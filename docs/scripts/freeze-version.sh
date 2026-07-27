#!/usr/bin/env bash
#
# freeze-version.sh — snapshot a shipped docs version into a browsable tree.
#
# Usage:  docs/scripts/freeze-version.sh <git-tag> <version>
# Example: docs/scripts/freeze-version.sh v1.2.0 1.2.0
#
# What it does:
#   1. Extracts ONLY the content pages (guide/ reference/ examples/ libraries/
#      index.md) from <git-tag> into docs/<version>/ — deliberately excluding
#      .vitepress (theme/config live only at docs/.vitepress), other frozen
#      version dirs, scripts/, and node_modules.
#   2. Rewrites internal ROOT-absolute markdown links to the /<version>/ prefix
#      (e.g. `](/reference/x)` -> `](/<version>/reference/x)`). External links
#      (http...), anchors (#...) and relative links (./x) are left untouched.
#      Links already carrying a /<n.n.n>/ version prefix are NOT re-prefixed.
#   3. Is idempotent: docs/<version>/ is wiped and rebuilt on every run.
#
# This is the reusable freeze step — see docs/RELEASING.md. On every version
# bump, freeze the OUTGOING version before moving root to the new one, and add
# it to the `versions` array in docs/.vitepress/theme/nav.ts.
#
set -euo pipefail

TAG="${1:-}"
VERSION="${2:-}"

if [[ -z "$TAG" || -z "$VERSION" ]]; then
  echo "usage: $0 <git-tag> <version>   e.g. $0 v1.2.0 1.2.0" >&2
  exit 2
fi

# docs/ is the parent of this script's scripts/ dir.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(git -C "$DOCS_DIR" rev-parse --show-toplevel)"

DEST="$DOCS_DIR/$VERSION"

# Make sure the tag exists.
if ! git -C "$REPO_ROOT" rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>&1 \
     && ! git -C "$REPO_ROOT" rev-parse -q --verify "$TAG^{commit}" >/dev/null 2>&1; then
  echo "error: git tag/ref '$TAG' not found" >&2
  exit 1
fi

echo "Freezing $TAG -> docs/$VERSION/"

# 1. Idempotent: clean any prior snapshot first.
rm -rf "$DEST"
mkdir -p "$DEST"

# 2. Extract only the content pages from the tag's docs/ subtree.
#    Using <tag>:docs as the tree-ish makes the pathspecs relative to docs/,
#    so archive entries land directly under $DEST.
git -C "$REPO_ROOT" archive --format=tar "$TAG:docs" \
    guide reference examples libraries index.md \
  | tar -x -C "$DEST"

# 3. Rewrite root-absolute internal links to the version prefix — both markdown
#    `](/x)` links AND raw-HTML attribute links (`href="/x"`, `src='/x'`), which
#    the pages use for hero buttons and card grids. Without the second rewrite a
#    frozen page would silently bounce the reader out to the LATEST docs (they
#    are not dead links, so no build check catches them).
#    The alternation only matches the content dirs, so a link that already
#    starts with `/<n.n.n>/` (e.g. `/1.2.0/guide`) begins with `](/1...` and
#    is never matched — no double-prefixing.
CONTENT='(guide|reference|examples|libraries|index)'
find "$DEST" -type f -name '*.md' -print0 \
  | xargs -0 sed -E -i \
      -e "s#\]\(/$CONTENT#](/$VERSION/\1#g" \
      -e "s#(href|src)=(\"|')/$CONTENT#\1=\2/$VERSION/\3#g"

MD_COUNT="$(find "$DEST" -name '*.md' | wc -l | tr -d ' ')"
echo "Done: $MD_COUNT markdown pages under docs/$VERSION/"
