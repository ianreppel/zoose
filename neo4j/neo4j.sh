#!/bin/bash
set -euo pipefail
neo4j start
exec /jupyter.sh "$@"
