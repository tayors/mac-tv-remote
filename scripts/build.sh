#!/bin/zsh
set -eu
REPO_DIR="${0:A:h:h}"
exec "$REPO_DIR/skills/build-tv-remote/assets/starter/build.sh" "$@"
