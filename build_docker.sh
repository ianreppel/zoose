#!/usr/bin/env bash
# Build every Zoose image from one Dockerfile.
# base is built first because every flavour inherits it. Each flavour then builds in its
# own `bake` call, so one broken flavour does not cancel the others; the summary at the
# end names every failure and prints the tail of its log.
set -uo pipefail
cd "$(dirname "$0")"
[ -f .env ] || { echo '.env is missing; it holds PREFIX and TAG' >&2; exit 1; }
set -a; source .env; set +a
images=(base pytorch quantum geo)
logs="$(mktemp -d "${TMPDIR:-/tmp}/zoose-build.XXXXXX")"
trap 'rm -rf "$logs"' EXIT

echo "== base"
if ! docker buildx bake --load base; then
  echo "FAIL base: nothing else can build without it"
  exit 1
fi

for f in "${images[@]:1}"; do
  ( docker buildx bake --load "$f" > "${logs}/zoose-build-${f}.log" 2>&1; echo $? > "${logs}/zoose-build-${f}.rc" ) &
done
wait

fail=0
echo "== summary"
echo "ok   base"
for f in "${images[@]:1}"; do
  rc="$(cat "${logs}/zoose-build-${f}.rc" 2>/dev/null || echo 1)"
  if [ "$rc" = "0" ]; then
    echo "ok   $f"
  else
    echo "FAIL $f (last 30 lines of its log)"
    tail -n 30 "${logs}/zoose-build-${f}.log"
    fail=1
  fi
done
exit "$fail"
