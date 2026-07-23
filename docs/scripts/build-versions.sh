#!/usr/bin/env bash
# Durable docs build: one vitepress process per version tree so peak memory is a
# single ~60-page tree, not all 540 pages at once (which OOM-killed Vercel).
# Each process is scoped by DOCS_BUILD_SCOPE (see .vitepress/config.mts). The
# frozen trees keep their /<version>/ routes, so everything lands in one dist/.
set -euo pipefail
cd "$(dirname "$0")/.."   # docs/

DIST=".vitepress/dist"
# Each scoped build handles only ~60 pages, so a small heap is plenty and keeps
# us far under any CI/Vercel container limit.
export NODE_OPTIONS="--max-old-space-size=4096"

rm -rf "$DIST"

echo "==> building latest tree"
DOCS_BUILD_SCOPE=latest npx vitepress build

# Discover frozen version trees (e.g. 1.8.0) and build each independently.
for dir in [0-9]*.[0-9]*.[0-9]*/; do
  [ -d "$dir" ] || continue
  v="${dir%/}"
  echo "==> building frozen tree $v"
  DOCS_BUILD_SCOPE="$v" npx vitepress build
done

echo "==> docs build complete: $(find "$DIST" -name '*.html' | wc -l) pages across $(( $(ls -d [0-9]*.[0-9]*.[0-9]*/ 2>/dev/null | wc -l) + 1 )) trees"
