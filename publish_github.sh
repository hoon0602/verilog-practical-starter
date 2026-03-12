#!/usr/bin/env bash
set -euo pipefail

REPO_NAME="verilog-practical-starter"
VISIBILITY="private"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --name)
            REPO_NAME="${2:-}"
            shift 2
            ;;
        --public)
            VISIBILITY="public"
            shift
            ;;
        --private)
            VISIBILITY="private"
            shift
            ;;
        *)
            echo "usage: $0 [--name <repo-name>] [--public|--private]" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$REPO_NAME" ]]; then
    echo "error: repository name must not be empty" >&2
    exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
    echo "error: 'gh' is not installed. run ./install_tools.sh first" >&2
    exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
    echo "error: GitHub CLI is not authenticated. run 'gh auth login' first" >&2
    exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
    echo "origin already exists:"
    git remote -v
    echo "if you want a new GitHub repo, remove or update origin first" >&2
    exit 1
fi

gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin --push

echo "repository published"
git remote -v
