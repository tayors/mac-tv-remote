#!/bin/zsh
set -eu
REPO_DIR="${0:A:h:h}"
exec "$REPO_DIR/app/build.sh" "$@"
