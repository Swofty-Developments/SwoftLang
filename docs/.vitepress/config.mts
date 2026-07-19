import { defineConfig } from 'vitepress'
import swoftlangGrammar from './swoftlang.tmLanguage.json'
import skriptGrammar from './skript.tmLanguage.json'

export default defineConfig({
  title: 'SwoftLang',
  description:
    'A scripting language for Minecraft servers — compiled by OCaml, executed on the JVM.',

  // dark-first; light is supported via the topbar toggle
  appearance: 'dark',

  vite: {
    server: {
      // allow tunnel hosts (localhost.run / cloudflare quick tunnels)
      allowedHosts: ['.lhr.life', '.trycloudflare.com']
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
