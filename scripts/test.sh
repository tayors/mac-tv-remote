#!/bin/sh
set -eu
REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$REPO_DIR/skills/build-tv-remote/assets/starter"
PYTHONPATH=. python3 -B -m unittest discover -s tests -v
