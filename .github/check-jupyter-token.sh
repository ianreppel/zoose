#!/bin/bash
# The notebook must never be open. With no ZOOSE_TOKEN the launcher must generate a random
# token, print it, refuse the API without it and accept the API and Lab with it. Base image
# only: all four flavours share this entrypoint.
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
image="${PREFIX}-base:${TAG}"
port=18888
base="http://127.0.0.1:${port}"
name=""
jar="$(mktemp)"
stop_container() { [ -n "$name" ] && docker rm -f "$name" >/dev/null 2>&1 || true; name=""; }
cleanup() { stop_container; rm -f "$jar"; }
trap cleanup EXIT

# A transport error is not a status: report 000 so the caller decides, and keep curl's own
# exit code out of the assignment, which set -e would otherwise end the script on.
status() { curl -s -o /dev/null -w '%{http_code}' --max-time 10 "$1" 2>/dev/null || true; }
# Jupyter answers a valid token with a cookie and a redirect to the clean URL, so follow the
# redirect with the cookie jar and read the final code.
auth_status() {
  curl -s -L --max-redirs 5 -c "$jar" -b "$jar" -o /dev/null -w '%{http_code}' --max-time 15 "$1" 2>/dev/null || true
}

# Jupyter binds the port seconds before it serves a reply, so poll until any HTTP answer arrives.
wait_serving() {
  local i code
  for i in $(seq 1 90); do
    code="$(status "${base}/api/status")"
    if [ -n "$code" ] && [ "$code" != "000" ]; then return 0; fi
    sleep 2
  done
  echo "FAIL: the notebook answered no HTTP request within 180 s"
  docker logs "$name" >&2 || true
  return 1
}

wait_for_token() {
  local i tok
  for i in $(seq 1 30); do
    tok="$(docker logs "$name" 2>&1 | grep -o 'token=[A-Za-z0-9_-]\{20,\}' | head -1 | cut -d= -f2 || true)"
    if [ -n "$tok" ]; then printf '%s' "$tok"; return 0; fi
    sleep 2
  done
  docker logs "$name" >&2 || true
  return 1
}

# No ZOOSE_TOKEN. An open notebook is the defect, so ask the API before looking for a token:
# reaching this line with 200 means the launcher served root without one.
name="zoose-token-${RANDOM}"
docker run -d --name "$name" -p "127.0.0.1:${port}:8888" "$image" >/dev/null
wait_serving
code="$(status "${base}/api/status")"
if [ "$code" = "200" ]; then echo "FAIL: the notebook is open: /api/status answered 200 with no token"; exit 1; fi
echo "GET /api/status with no token: ${code}"

token="$(wait_for_token)" || { echo "FAIL: the launcher printed no token"; exit 1; }
echo "generated token: ${token:0:6}... (length ${#token})"

code="$(auth_status "${base}/api/status?token=${token}")"
if [ "$code" != "200" ]; then echo "FAIL: /api/status with the generated token answered ${code}"; exit 1; fi
echo "GET /api/status with the generated token: 200"

code="$(auth_status "${base}/lab?token=${token}")"
if [ "$code" != "200" ]; then echo "FAIL: /lab with the generated token answered ${code}"; exit 1; fi
echo "GET /lab with the generated token: 200"
stop_container

# ZOOSE_TOKEN set: the launcher must print that token, not one of its own.
name="zoose-token-fixed-${RANDOM}"
fixed="fixed-token-0123456789"
docker run -d --name "$name" -p "127.0.0.1:${port}:8888" -e "ZOOSE_TOKEN=${fixed}" "$image" >/dev/null
wait_serving
token="$(wait_for_token)" || { echo "FAIL: the launcher printed no token with ZOOSE_TOKEN set"; exit 1; }
if [ "$token" != "$fixed" ]; then echo "FAIL: the launcher printed ${token}, not the set ZOOSE_TOKEN"; exit 1; fi
echo "ZOOSE_TOKEN set: the launcher prints the set token"

code="$(auth_status "${base}/lab?token=${fixed}")"
if [ "$code" != "200" ]; then echo "FAIL: /lab with the set token answered ${code}"; exit 1; fi
echo "token gate: PASS"
