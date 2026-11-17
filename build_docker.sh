#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# Local base must exist before any derived image; Gitpod must inherit its own flavour.
docker compose build base
docker compose build neo4j pytorch quantum geo
docker compose build base-gitpod pytorch-gitpod quantum-gitpod geo-gitpod
