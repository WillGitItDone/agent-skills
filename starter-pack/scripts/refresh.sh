#!/bin/bash
# Refresh all Pillar repos to latest from their default branches
set -e

REPOS_DIR="$(cd "$(dirname "$0")/../repos" && pwd)"

echo "🔄 Refreshing Pillar repos..."
echo ""

for repo in "$REPOS_DIR"/*/; do
  name=$(basename "$repo")
  cd "$repo"
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "detached")
  
  echo "  📦 $name ($branch)"
  
  # Stash any local changes
  if ! git diff --quiet 2>/dev/null || ! git diff --cached --quiet 2>/dev/null; then
    echo "     ⚠️  Stashing local changes"
    git stash --quiet
  fi
  
  # Pull latest
  if git pull --quiet 2>/dev/null; then
    echo "     ✅ Up to date"
  else
    echo "     ❌ Pull failed — check manually"
  fi
  
  echo ""
done

echo "Done."
