#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
for flavour in base neo4j pytorch quantum geo gitpod; do
  docker run --pull always --rm -i -v "$PWD/hadolint.yaml:/.config/hadolint.yaml:ro" \
    hadolint/hadolint < "$flavour/Dockerfile"
done
