import { guideSteps } from './steps'

/**
 * The persistent left-sidebar tree. One entry per group; groups may carry
 * ungrouped `items` (shown first, e.g. an Overview link) and named
 * `subgroups`. `match` decides which group a route belongs to, so the
 * active group opens and the current page highlights.
 *
 * This tree is the site's map — adding a page means adding it here.
 */
export interface NavLink {
  text: string
  link: string
  /** zero-padded numeral, guide steps only */
  num?: string
}

export interface NavSubgroup {
  text: string
  items: NavLink[]
}

export interface NavGroup {
  text: string
  link: string
  match: RegExp
  items?: NavLink[]
  subgroups?: NavSubgroup[]
}

/** The guide is the numbered course; its numerals come straight from steps.ts. */
const guideItems: NavLink[] = guideSteps.map((s) => ({
  text: s.title,
  link: s.path,
  num: String(s.n).padStart(2, '0')
}))

export const navGroups: NavGroup[] = [
  {
    text: 'Guide',
    link: '/guide/',
    match: /^\/guide\//,
    items: guideItems
  },
  {
    text: 'Reference',
    link: '/reference/',
    match: /^\/reference\//,
    items: [{ text: 'Overview', link: '/reference/' }],
    subgroups: [
      {
        text: 'Language',
        items: [
          { text: 'Syntax Cheatsheet', link: '/reference/syntax-cheatsheet' },
          { text: 'Maps', link: '/reference/maps' },
          { text: 'Collections & Strings', link: '/reference/collections' },
          { text: 'Builtins', link: '/reference/builtins' },
          { text: 'Receivers & Events', link: '/reference/events' },
          { text: 'CLI (swoftc)', link: '/reference/cli' }
        ]
      },
      {
        text: 'Content',
        items: [
          { text: 'Custom Items', link: '/reference/items' },
          { text: 'Custom Mobs', link: '/reference/mobs' },
          { text: 'Entities', link: '/reference/entities' },
          { text: 'Combat & PvP', link: '/reference/combat' },
          { text: 'Fishing', link: '/reference/fishing' },
          { text: 'Dispensers & Droppers', link: '/reference/dispensers' },
          { text: 'Offline Players', link: '/reference/offline-players' },
          { text: 'GUIs', link: '/reference/gui' },
          { text: 'Scoreboards & Tablists', link: '/reference/scoreboards-tablists' },
          { text: 'Nametags', link: '/reference/nametags' },
          { text: 'Displays', link: '/reference/displays' },
          { text: 'Holograms', link: '/reference/holograms' },
          { text: 'NPCs', link: '/reference/npcs' }
        ]
      },
      {
        text: 'Platform',
        items: [
          { text: 'Server Config', link: '/reference/server-config' },
          { text: 'Worlds', link: '/reference/worlds' },
          { text: 'Blocks', link: '/reference/blocks' },
          { text: 'HTTP API', link: '/reference/http-api' },
          { text: 'Songs', link: '/reference/songs' },
          { text: 'Maps, Toasts, Skins & TPS', link: '/reference/maps-toasts-skins-tps' },
          { text: 'Schedulers', link: '/reference/schedulers' },
          { text: 'Raw Packets', link: '/reference/packets' }
        ]
      },
      {
        text: 'Internals',
        items: [{ text: 'JSON AST', link: '/reference/json-ast' }]
      }
    ]
  },
  {
    text: 'Libraries',
    link: '/libraries/',
    match: /^\/libraries\//,
    items: [{ text: 'Overview', link: '/libraries/' }],
    subgroups: [
      {
        text: 'Shipped addons',
        items: [
          { text: 'Music', link: '/libraries/music' },
          { text: 'Abilities', link: '/libraries/abilities' }
        ]
      },
      {
        text: 'Authoring',
        items: [{ text: 'Writing an Addon', link: '/libraries/writing-an-addon' }]
      }
    ]
  },
  {
    text: 'Examples',
    link: '/examples/',
    match: /^\/examples\//,
    items: [{ text: 'Overview', link: '/examples/' }],
    subgroups: [
      {
        text: 'Ported plugins',
        items: [
          { text: 'StaffChat', link: '/examples/staffchat' },
          { text: 'Player Vault', link: '/examples/player-vault' },
          { text: 'Rules', link: '/examples/rules' },
          { text: 'Admin tools', link: '/examples/admin' },
          { text: 'Throwable slime', link: '/examples/throwable-slime' },
          { text: 'WardenSK', link: '/examples/wardensk' }
        ]
      }
    ]
  }
]

/* --------------------------------------------------------------------------
 * Versioning
 *
 * The tree above is the LATEST (root) docs. Older releases are frozen under a
 * path prefix (e.g. `/1.1.0/`) with their own copy of the pages. Each frozen
 * release carries its own sidebar so navigating into it swaps the whole tree.
 * `sidebarForPath` picks the right tree by route; the top-right version
 * switcher (see `versions`) jumps between them.
 * ------------------------------------------------------------------------ */

export interface DocVersion {
  /** dropdown label */
  text: string
  /** entry point for that version */
  link: string
  /** short badge shown on the switcher button, e.g. `v1.2.0` */
  label: string
  /** route prefix that identifies pages of this version ('' = root/latest) */
  prefix: string
}

/** Newest first. The first entry is the latest (root) docs. */
export const versions: DocVersion[] = [
  { text: '1.4.0 (latest)', link: '/', label: 'v1.4.0', prefix: '' },
  { text: '1.1.0', link: '/1.1.0/', label: 'v1.1.0', prefix: '/1.1.0' }
]

/** The frozen 1.1.0 tree — its OWN pages under `/1.1.0/`, with 1.1.0 labels. */
const guideItems110: NavLink[] = guideSteps.map((s) => ({
  text: s.title,
  link: '/1.1.0' + s.path,
  num: String(s.n).padStart(2, '0')
}))

export const navGroups110: NavGroup[] = [
  {
    text: 'Guide',
    link: '/1.1.0/guide/',
    match: /^\/1\.1\.0\/guide\//,
    items: guideItems110
  },
  {
    text: 'Reference',
    link: '/1.1.0/reference/',
    match: /^\/1\.1\.0\/reference\//,
    items: [{ text: 'Overview', link: '/1.1.0/reference/' }],
    subgroups: [
      {
        text: 'Language',
        items: [
          { text: 'Syntax Cheatsheet', link: '/1.1.0/reference/syntax-cheatsheet' },
          { text: 'Maps', link: '/1.1.0/reference/maps' },
          { text: 'Collections & Strings', link: '/1.1.0/reference/collections' },
          { text: 'Builtins', link: '/1.1.0/reference/builtins' },
          { text: 'Event Catalog', link: '/1.1.0/reference/events' },
          { text: 'CLI (swoftc)', link: '/1.1.0/reference/cli' }
        ]
      },
      {
        text: 'Content',
        items: [
          { text: 'Custom Items', link: '/1.1.0/reference/items' },
          { text: 'Custom Mobs', link: '/1.1.0/reference/mobs' },
          { text: 'Entities', link: '/1.1.0/reference/entities' },
          { text: 'Combat & PvP', link: '/1.1.0/reference/combat' },
          { text: 'Fishing', link: '/1.1.0/reference/fishing' },
          { text: 'Dispensers & Droppers', link: '/1.1.0/reference/dispensers' },
          { text: 'Offline Players', link: '/1.1.0/reference/offline-players' },
          { text: 'GUIs', link: '/1.1.0/reference/gui' },
          { text: 'Scoreboards & Tablists', link: '/1.1.0/reference/scoreboards-tablists' },
          { text: 'Nametags', link: '/1.1.0/reference/nametags' },
          { text: 'Displays', link: '/1.1.0/reference/displays' },
          { text: 'Holograms', link: '/1.1.0/reference/holograms' },
          { text: 'NPCs', link: '/1.1.0/reference/npcs' }
        ]
      },
      {
        text: 'Platform',
        items: [
          { text: 'Server Config', link: '/1.1.0/reference/server-config' },
          { text: 'Worlds', link: '/1.1.0/reference/worlds' },
          { text: 'Blocks', link: '/1.1.0/reference/blocks' },
          { text: 'HTTP API', link: '/1.1.0/reference/http-api' },
          { text: 'Songs', link: '/1.1.0/reference/songs' },
          { text: 'Maps, Toasts, Skins & TPS', link: '/1.1.0/reference/maps-toasts-skins-tps' },
          { text: 'Schedulers', link: '/1.1.0/reference/schedulers' },
          { text: 'Raw Packets', link: '/1.1.0/reference/packets' }
        ]
      },
      {
        text: 'Internals',
        items: [{ text: 'JSON AST', link: '/1.1.0/reference/json-ast' }]
      }
    ]
  },
  {
    text: 'Libraries',
    link: '/1.1.0/libraries/',
    match: /^\/1\.1\.0\/libraries\//,
    items: [{ text: 'Overview', link: '/1.1.0/libraries/' }],
    subgroups: [
      {
        text: 'Shipped addons',
        items: [
          { text: 'Music', link: '/1.1.0/libraries/music' },
          { text: 'Abilities', link: '/1.1.0/libraries/abilities' }
        ]
      },
      {
        text: 'Authoring',
        items: [{ text: 'Writing an Addon', link: '/1.1.0/libraries/writing-an-addon' }]
      }
    ]
  },
  {
    text: 'Examples',
    link: '/1.1.0/examples/',
    match: /^\/1\.1\.0\/examples\//,
    items: [{ text: 'Overview', link: '/1.1.0/examples/' }],
    subgroups: [
      {
        text: 'Ported plugins',
        items: [
          { text: 'StaffChat', link: '/1.1.0/examples/staffchat' },
          { text: 'Player Vault', link: '/1.1.0/examples/player-vault' },
          { text: 'Rules', link: '/1.1.0/examples/rules' },
          { text: 'Admin tools', link: '/1.1.0/examples/admin' },
          { text: 'Throwable slime', link: '/1.1.0/examples/throwable-slime' },
          { text: 'WardenSK', link: '/1.1.0/examples/wardensk' }
        ]
      }
    ]
  }
]

/** Route prefix `/1.1.0/` gets the frozen tree; everything else is latest. */
const V110 = /^\/1\.1\.0\//

/** The sidebar tree for a given route (version-aware). */
export function sidebarForPath(path: string): NavGroup[] {
  return V110.test(path) ? navGroups110 : navGroups
}

/** The version descriptor a route belongs to (defaults to latest/root). */
export function versionForPath(path: string): DocVersion {
  return versions.find((v) => v.prefix && path.startsWith(v.prefix + '/')) ?? versions[0]
}
