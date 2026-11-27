#!/bin/bash
set -euo pipefail
token="${ZOOSE_TOKEN-}"
if [ -z "${token}" ]; then
  token="$(python -c 'import secrets; print(secrets.token_urlsafe(32))')"
  echo "ZOOSE_TOKEN is empty: a random token guards this session." >&2
fi
export ZOOSE_TOKEN="${token}"
# Printed for both open paths: this terminal on the host, and a Codespaces forwarded port.
echo "JupyterLab: http://localhost:8888/lab?token=${token}" >&2
exec jupyter lab --ServerApp.ip=0.0.0.0 --ServerApp.port=8888 \
  --ServerApp.allow_root=True --ServerApp.open_browser=False \
  --IdentityProvider.token="${token}" --PasswordIdentityProvider.hashed_password='' \
  --LabServerApp.notebook_starts_kernel=True "$@"
