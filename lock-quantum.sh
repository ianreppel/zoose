#!/bin/bash
# Re-lock Zoose Quantum without Docker. Needs uv: https://docs.astral.sh/uv/
# Resolves quantum/requirements.in to the newest compatible versions for Python 3.12,
# which is the Python version of the base image. Pre-releases are never locked:
# pennylane-lightning 0.45 asks for a PennyLane development build, and a lock must not hold one.
set -euo pipefail
cd "$(dirname "$0")"
uv pip compile quantum/requirements.in \
  --python-version 3.12 \
  --upgrade \
  --prerelease disallow \
  --no-header \
  --annotation-style line \
  --output-file quantum/requirements.txt
echo "locked: quantum/requirements.txt"
echo "next: python3 smoke_quantum.py (in a fresh venv) before you push"
