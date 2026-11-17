#!/usr/bin/env bash
# One Dockerfile now, so one lint pass covers every image.
set -euo pipefail
cd "$(dirname "$0")"
docker run --pull always --rm -i -v "$PWD/hadolint.yaml:/.config/hadolint.yaml:ro" \
  hadolint/hadolint < Dockerfile
