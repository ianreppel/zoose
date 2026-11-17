#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
source .env
for flavour in base neo4j pytorch quantum geo; do
  image="${PREFIX}-${flavour}:${TAG}"
  docker run --rm --entrypoint python -v "$PWD:/checks:ro" "$image" -I /checks/smoke.py "${flavour}"
  docker run --rm --entrypoint python -v "$PWD:/checks:ro" "$image" -I /checks/smoke_jupyter.py
  docker run --rm --entrypoint pip "$image" check
done
# Exercise the database as well as the offline neo4j client.
docker run --rm --entrypoint bash -v "$PWD:/checks:ro" -e ZOOSE_NEO4J_LIVE=1 \
  "${PREFIX}-neo4j:${TAG}" -ec 'neo4j start; python -I /checks/smoke.py neo4j'
