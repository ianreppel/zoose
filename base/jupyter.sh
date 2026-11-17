#!/bin/bash
set -euo pipefail
exec jupyter lab --ServerApp.ip=0.0.0.0 --ServerApp.port=8888 \
  --ServerApp.allow_root=True --ServerApp.open_browser=False \
  --IdentityProvider.token="${ZOOSE_TOKEN-}" --PasswordIdentityProvider.hashed_password='' \
  --LabServerApp.notebook_starts_kernel=True "$@"
