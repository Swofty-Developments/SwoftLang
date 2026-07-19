export interface GuideStep {
  n: number
  path: string
  title: string
}

/**
 * The guide is a numbered course. Order here drives the StepHeader
 * numerals and the prev/next footer navigation on every /guide/ page.
 */
export const guideSteps: GuideStep[] = [
  { n: 1, path: '/guide/', title: 'Setup' },
  { n: 2, path: '/guide/commands', title: 'Your First Command' },
  { n: 3, path: '/guide/events', title: 'Events' },
  { n: 4, path: '/guide/variables-and-types', title: 'Variables & Types' },
  { n: 5, path: '/guide/control-flow', title: 'Control Flow' },
  { n: 6, path: '/guide/functions', title: 'Functions & Lambdas' },
  { n: 7, path: '/guide/options', title: 'Options — No More Null' },
  { n: 8, path: '/guide/properties', title: 'Player & World Properties' },
  { n: 9, path: '/guide/async', title: 'Async' },
  { n: 10, path: '/guide/persistence', title: 'Persistence' },
  { n: 11, path: '/guide/guis', title: 'GUIs' },
  { n: 12, path: '/guide/items-and-mobs', title: 'Items & Mobs' },
  { n: 13, path: '/guide/modules', title: 'Modules & Addons' },
  { n: 14, path: '/guide/rpg-items', title: 'Build an RPG Item System' },
  { n: 15, path: '/guide/offline-players', title: 'Offline Players' },
  { n: 16, path: '/guide/ship-it', title: 'Ship It' }
]

export function normalizePath(path: string): string {
  return path.replace(/\.html$/, '').replace(/index$/, '')
}

export function findStep(path: string): GuideStep | undefined {
  const p = normalizePath(path)
  return guideSteps.find((s) => s.path === p)
}
