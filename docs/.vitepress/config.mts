import { defineConfig } from 'vitepress'
import { readdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import swoftlangGrammar from './swoftlang.tmLanguage.json'
import skriptGrammar from './skript.tmLanguage.json'

// --- Scoped builds -------------------------------------------------------
// Building all frozen version trees (~540 pages) in one process OOM-killed
// Vercel's build container. Instead the build script (scripts/build-versions.sh)
// invokes vitepress once per tree, each scoped to a single version via
// DOCS_BUILD_SCOPE, so peak memory is one ~60-page tree — flat no matter how
// many versions we freeze. Frozen trees keep their /<version>/-prefixed routes
// (srcDir stays docs/), so base stays '/' and their built HTML lands in
// dist/<version>/ with shared assets. scope 'all' = the old monolithic build
// (dev / local full build).
const DOCS_ROOT = fileURLToPath(new URL('..', import.meta.url))
const VERSION_RE = /^\d+\.\d+\.\d+$/
const FROZEN = readdirSync(DOCS_ROOT, { withFileTypes: true })
  .filter((d) => d.isDirectory() && VERSION_RE.test(d.name))
  .map((d) => d.name)
  .sort()
const LATEST_ROOTS = ['guide/**', 'reference/**', 'examples/**', 'libraries/**', 'index.md']
const scope = process.env.DOCS_BUILD_SCOPE || 'all'
const srcExclude =
  scope === 'all'
    ? []
    : scope === 'latest'
      ? FROZEN.map((v) => `${v}/**`)
      : [...LATEST_ROOTS, ...FROZEN.filter((v) => v !== scope).map((v) => `${v}/**`)]
// The build script pre-clears dist and appends each scoped build, so only the
// monolithic 'all' build should empty the output directory.
const emptyOutDir = scope === 'all'
// -------------------------------------------------------------------------

export default defineConfig({
  srcExclude,
  // Frozen trees carry valid cross-tree back-links (e.g. to the latest home) that
  // a single-tree build can't see; those targets exist at serve time. Keep the
  // check for the actively-edited 'latest' and the monolithic 'all' build.
  ignoreDeadLinks: scope !== 'all' && scope !== 'latest',
  title: 'SwoftLang',
  description:
    'A scripting language for Minecraft servers — compiled by OCaml, executed on the JVM.',

  // dark-first; light is supported via the topbar toggle
  appearance: 'dark',

  vite: {
    server: {
      // allow tunnel hosts (localhost.run / cloudflare quick tunnels)
      allowedHosts: ['.lhr.life', '.trycloudflare.com']
    },
    build: {
      // Docs JS is tiny and cache-busted; skipping minify trims build memory.
      minify: false,
      chunkSizeWarningLimit: 4096,
      // Per-version scoped builds append to a script-pre-cleared dist.
      emptyOutDir
    }
  },

  head: [
    [
      'link',
      {
        rel: 'icon',
        type: 'image/svg+xml',
        href: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'%3E%3Crect width='100' height='100' rx='22' fill='%23059669'/%3E%3Ctext x='50' y='70' font-size='58' font-family='ui-sans-serif,system-ui,sans-serif' font-weight='700' fill='white' text-anchor='middle'%3ES%3C/text%3E%3C/svg%3E"
      }
    ]
  ],

  markdown: {
    theme: {
      light: 'vitesse-light',
      dark: 'vitesse-dark'
    },
    languages: [
      {
        ...(swoftlangGrammar as any),
        name: 'swoftlang',
        aliases: ['sw']
      },
      {
        ...(skriptGrammar as any),
        name: 'skript',
        aliases: ['sk']
      }
    ]
  },

  themeConfig: {
    // used by the custom theme's search modal (VPLocalSearchBox)
    search: {
      provider: 'local'
    }
  }
})
