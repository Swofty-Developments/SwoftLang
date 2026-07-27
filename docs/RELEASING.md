# Releasing the docs

The docs site serves the **latest** version at the root (`docs/guide/`,
`docs/reference/`, …) and keeps every older shipped release as a frozen,
browsable snapshot under a `/<version>/` path prefix (`docs/1.1.0/`,
`docs/1.2.0/`, …). The top-right version switcher and the per-version sidebar
are driven by `docs/.vitepress/theme/nav.ts`.

## Default: freeze on every version bump

Whenever you bump the docs to a new version, **freeze the outgoing version
first**, before you edit the root pages for the new one. Freezing is not
optional — a shipped version with no snapshot is a gap.

For a bump from `X` (current root) to `Y`:

1. Freeze the outgoing version `X` from its release tag:

   ```sh
   docs/scripts/freeze-version.sh v<X> <X>      # e.g. v1.3.0 1.3.0
   ```

   This creates `docs/<X>/` with only the content pages (guide, reference,
   examples, libraries, index.md — no `.vitepress`), and rewrites internal
   root-absolute links to the `/<X>/` prefix — both markdown `](/…)` links and
   the raw-HTML `href="/…"` / `src="/…"` attributes the hero and card grids
   use. (Raw HTML is invisible to the dead-link checker, so without that
   rewrite a frozen page silently bounces the reader out to the latest docs.)
   It is idempotent (`docs/<X>/` is wiped and rebuilt), so it is safe to
   re-run — and re-running 1.2.0 and later is how you backfill a rewrite the
   script learns later. **Do not re-run it for 1.1.0**: that tree was
   hand-corrected after its freeze (a "you are viewing 1.1.0" banner, plus
   link fixes and pages the v1.1.0 tag never had), so a re-freeze silently
   reverts all of it. Check `git status` after any bulk re-freeze.

2. Register `X` in the `versions` array in
   `docs/.vitepress/theme/nav.ts` (newest first). Add a generated sidebar with
   `makeVersionGroups('/<X>')` and route `/<X>/*` to it in `sidebarForPath`.
   Older versions whose page set matches root need no hand-editing — the
   sidebar is generated from the root `navGroups`. (1.1.0 predates the
   receiver/event redesign and keeps a hand-built `navGroups110`.)

3. Update the root pages for the new latest version `Y` and set its label as
   `(latest)` in `versions` (root entry, `prefix: ''`).

4. Build to confirm every tree still renders:

   ```sh
   cd docs && npm run docs:build
   ```

   This is the shipping build: one vitepress process per version tree, so peak
   memory stays at one ~60-page tree. Because a single-tree process cannot see
   the other trees' pages, it only dead-link-checks root; the frozen trees are
   built with `ignoreDeadLinks`. To dead-link-check **every** tree at once, run
   the monolithic build (all ~600 pages in one process — needs the big heap,
   which is why it is not what CI/Vercel runs):

   ```sh
   cd docs && npm run docs:build:full
   ```

## Backfilling a version that was never frozen

Same as step 1–2 above — the freeze script reconstructs the snapshot straight
from the git tag, so a missed freeze can always be recovered later.
