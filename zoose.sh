#!/bin/bash
# Usage:           ./zoose.sh [FLAVOUR]
# FLAVOUR options: base neo4j pytorch quantum geo
# FLAVOUR default: base
# Example:         ./zoose.sh neo4j
#
# The image is used if it exists locally, and built if it does not: the 6.0.0 tags are
# not published on Docker Hub, so a fresh clone has nothing to run and nothing to pull.
set -euo pipefail
cd "$(dirname "$0")"
set -a; source .env; set +a
FLAVOUR="${1:-base}"
IMAGE="${PREFIX}-${FLAVOUR}:${TAG}"

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "${IMAGE} is not present locally; building it with docker buildx bake."
  docker buildx bake --load "${FLAVOUR}"
fi

echo "Launching ${IMAGE}..."

if [ "${FLAVOUR}" = "neo4j" ]; then
  docker run --rm -it \
    -v "$(pwd):$(pwd)" \
    -w "$(pwd)" \
    -p 8888:8888 \
    -p 7473:7473 \
    -p 7474:7474 \
    -p 7687:7687 \
    "${IMAGE}"
else
  docker run --rm -it \
    -v "$(pwd):$(pwd)" \
    -w "$(pwd)" \
    -p 8888:8888 \
    "${IMAGE}"
fi
