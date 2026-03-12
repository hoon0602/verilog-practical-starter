#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: $0 <github-remote-url>" >&2
    echo "example: $0 git@github.com:your-id/verilog-practical-starter.git" >&2
    exit 1
fi

REMOTE_URL="$1"

if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REMOTE_URL"
    echo "updated origin -> $REMOTE_URL"
else
    git remote add origin "$REMOTE_URL"
    echo "added origin -> $REMOTE_URL"
fi

git remote -v
