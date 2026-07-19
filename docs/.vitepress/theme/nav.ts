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
          { text: 'Builtins', link: '/reference/builtins' },
          { text: 'Event Catalog', link: '/reference/events' },
          { text: 'CLI (swoftc)', link: '/reference/cli' }
        ]
      },
      {
        text: 'Content',
        items: [
          { text: 'Custom Items', link: '/reference/items' },
          { text: 'Custom Mobs', link: '/reference/mobs' },
          { text: 'Entities', link: '/reference/entities' },
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
          { text: 'Worlds & Blocks', link: '/reference/worlds' },
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
