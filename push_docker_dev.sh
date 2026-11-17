#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
source .env
# Guard manual publishing too: no image is pushed until the complete suite passes.
./.github/smoke-images.sh
for flavour in base neo4j pytorch quantum geo; do
  docker tag "${PREFIX}-${flavour}:${TAG}" "${PREFIX}-${flavour}:dev-${TAG}"
  docker push "${PREFIX}-${flavour}:dev-${TAG}"
done
