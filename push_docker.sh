#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source .env
# Guard manual publishing too: no image is pushed until the complete suite passes.
./.github/smoke-images.sh
for flavour in base neo4j pytorch quantum geo base-gitpod pytorch-gitpod quantum-gitpod geo-gitpod; do
  docker push "${PREFIX}-${flavour}:${TAG}"
  docker tag "${PREFIX}-${flavour}:${TAG}" "${PREFIX}-${flavour}:latest"
  docker push "${PREFIX}-${flavour}:latest"
done
