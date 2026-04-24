#!/usr/bin/env bash
# Link skills from this repo into a workspace's .cursor/skills/ (Cursor).
# Usage:
#   ./scripts/install-cursor-symlinks.sh
#   ./scripts/install-cursor-symlinks.sh /path/to/your/REPOS
#
# Default target is the parent of this repo (e.g. .../REPOS when ai-skills lives at .../REPOS/ai-skills).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORKSPACE_ROOT="${1:-$REPO_ROOT/..}"
WORKSPACE_ROOT="$(cd "$WORKSPACE_ROOT" && pwd)"
TARGET="$WORKSPACE_ROOT/.cursor/skills"

mkdir -p "$TARGET"
shopt -s nullglob
for d in "$REPO_ROOT"/skills/*; do
  [[ -d "$d" ]] || continue
  name="$(basename "$d")"
  ln -sfn "$d" "$TARGET/$name"
  echo "Cursor: linked $name -> $TARGET/$name"
done
echo "Done. Target: $TARGET"
