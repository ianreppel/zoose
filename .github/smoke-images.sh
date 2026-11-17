#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
for flavour in base pytorch quantum geo; do
  image="${PREFIX}-${flavour}:${TAG}"
  docker run --rm --entrypoint python -v "$PWD:/checks:ro" "$image" -I /checks/smoke.py "${flavour}"
  docker run --rm --entrypoint python -v "$PWD:/checks:ro" "$image" -I /checks/smoke_jupyter.py
  docker run --rm --entrypoint uv "$image" pip check --system
done
