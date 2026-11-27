#!/usr/bin/env bash
# One Dockerfile now, so one lint pass covers every image.
set -euo pipefail
cd "$(dirname "$0")"
docker run --pull always --rm -i -v "$PWD/hadolint.yaml:/.config/hadolint.yaml:ro" \
  hadolint/hadolint:v2.14.0@sha256:27086352fd5e1907ea2b934eb1023f217c5ae087992eb59fde121dce9c9ff21e < Dockerfile
