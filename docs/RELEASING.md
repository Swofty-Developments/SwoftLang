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
   root-absolute markdown links to the `/<X>/` prefix. It is idempotent
   (`docs/<X>/` is wiped and rebuilt), so it is safe to re-run.

2. Register `X` in the `versions` array in
   `docs/.vitepress/theme/nav.ts` (newest first). Add a generated sidebar with
   `makeVersionGroups('/<X>')` and route `/<X>/*` to it in `sidebarForPath`.
   Older versions whose page set matches root need no hand-editing — the
   sidebar is generated from the root `navGroups`. (1.1.0 predates the
   receiver/event redesign and keeps a hand-built `navGroups110`.)

3. Update the root pages for the new latest version `Y` and set its label as
   `(latest)` in `versions` (root entry, `prefix: ''`).

4. Build to confirm no dead links across every frozen tree and root:

   ```sh
   cd docs && npm run docs:build
   ```

## Backfilling a version that was never frozen

Same as step 1–2 above — the freeze script reconstructs the snapshot straight
from the git tag, so a missed freeze can always be recovered later.
