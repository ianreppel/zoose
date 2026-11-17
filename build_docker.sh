#!/usr/bin/env bash
# Build every Zoose image from one graph. Flavours build in parallel; base is built once
# as a dependency, and nothing needs a published base image first.
set -euo pipefail
cd "$(dirname "$0")"
set -a; source .env; set +a
exec docker buildx bake --load "$@"
