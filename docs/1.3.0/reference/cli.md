# CLI (swoftc)

`swoftc` is the OCaml compiler binary. It does all parsing and checking; the Java
runtime never sees a `.sw` file it hasn't blessed.

```
Usage: swoftc compile <file.sw...> [--addon-path <dir>] [-o <out.json>] | swoftc check <file.sw...> [--addon-path <dir>] | swoftc --property-table | swoftc --version
```

## Commands

### `swoftc compile <file.sw...> [--addon-path <dir>] [-o <out.json>]`

Parses, typechecks, and emits the [JSON AST](./json-ast) — pretty-printed to stdout,
or to a file with `-o`. Nothing is emitted if any check fails. Multiple entry files
compile as one unit; [imports](/1.3.0/libraries/) are resolved transitively and the whole
module graph lands in a single bundle document.

```sh
swoftc compile scripts/showcase.sw            # JSON to stdout
swoftc compile scripts/showcase.sw -o scripts/showcase.sw.json
swoftc compile scripts/lobby.sw --addon-path addons -o scripts/lobby.sw.json
```

### `swoftc check <file.sw...> [--addon-path <dir>]`

Front end only: parse + typecheck (including every imported module), no output on
success. This is the fast feedback loop for editors and CI.

```sh
swoftc check scripts/showcase.sw && echo ok
swoftc check scripts/lobby.sw --addon-path addons
```

### `--addon-path <dir>`

Where `import "name"` looks for modules, after the importing script's own directory.
Defaults to `./addons` next to the scripts. Relative imports (`import "./util.sw"`)
ignore it. See [the module system](/1.3.0/libraries/#the-import-system) for resolution
details.

### `swoftc --version`

```
swoftc 2.0.0
```

### `swoftc --property-table`

Dumps the compiler's property registry as JSON — every `owner` / `name` / `type` /
`writable` row the typechecker uses for dotted paths:

```json
[
  { "owner": "Player", "name": "name", "type": "String", "writable": false },
  { "owner": "Player", "name": "health", "type": "Double", "writable": true },
  ...
]
```

This table must match the Java runtime's `PropertyRegistry`; the Java test harness
consumes this exact output to keep the two sides honest. It's also handy for building
editor tooling.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | success (`check` passed / `compile` emitted JSON) |
| `1` | compile error (parse or typecheck) or unreadable input file |
| `2` | usage error (bad arguments) |

## Diagnostics {#diagnostics}

Errors are written twice, for two audiences:

- **stderr** — human-readable, `file:line:col: error: message` plus a caret snippet.
  On typecheck failures, *every* error is printed, not just the first.
- **stdout** — one machine-readable JSON object (the first error):

```
$ swoftc check e_parse.sw
e_parse.sw:3:22: error: Unexpected identifier 'ot' at start of statement
        send "hello" ot sender
                     ^
$ echo $?
1
```

```json
{ "error": { "message": "Unexpected identifier 'ot' at start of statement", "line": 3, "col": 22 } }
```

Warnings (for example an unknown argument type: `warning: unknown type 'Thing',
treating as UNKNOWN`) go to stderr and do **not** block compilation — exit code stays
0. The Java runtime forwards them to the server log prefixed `[swoftc]`.

## How the runtime finds swoftc

At script load, the Java side (`net.swofty.compiler.SwoftcCompiler`) resolves the
binary in this order:

1. **`SWOFTC` environment variable** — absolute path to the binary. Wins if set,
   executable, and present.
2. **`swoftc` on `PATH`** — first executable hit, scanning `PATH` in order.
3. **Repo-relative build** — walks up from the working directory looking for
   `compiler/_build/default/bin/main.exe` (the dune output), so a source checkout
   just works.
4. **Sidecar fallback** — no binary anywhere: a `<script>.sw.json` file next to the
   script is loaded instead.

If all four miss, loading fails with an error listing everything that was checked.

The runtime invokes `swoftc compile <absolute-path>` and reads stdout; a non-zero exit
turns into a load error carrying swoftc's stderr text.

```sh
# pin an explicit binary (systemd unit, Docker, etc.)
SWOFTC=/opt/swoftlang/bin/swoftc java -jar server.jar
```

## Sidecars {#sidecars}

The sidecar mechanism decouples *compiling* from *running*: production servers don't
need OCaml installed.

```sh
# on your dev machine / CI — compile every script next to itself
for f in scripts/*.sw; do
    swoftc compile "$f" -o "$f.json"
done

# ship scripts/ (both .sw and .sw.json); the server uses the sidecars
```

Rules of thumb:

- The sidecar is used **only** when no binary resolves — a present `swoftc` always
  recompiles from source, so stale sidecars can't shadow fresh edits during
  development.
- Regenerate sidecars whenever the `.sw` changes; they are plain build artifacts.
  Committing them is fine (this repo does) — diffs double as an AST changelog.
- Each script is compiled once per load and cached; reloads re-run the pipeline.

::: tip CI in one line
`swoftc check` on every `.sw` file is the whole lint story — types, options, async
coloring, property names, GUI slot math, sidebar caps. If CI is green, the scripts
load.
:::
