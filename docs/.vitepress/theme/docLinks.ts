// Client-side doc affordances:
//  - click a heading (or its anchor) to copy a deep link to it
//  - a "copy link" button on every code block (beside the copy-code button)
//  - deep links to code blocks scroll to + briefly flash the block
import type { Router } from 'vitepress'

function toast(msg: string) {
  let el = document.getElementById('sw-copy-toast')
  if (!el) {
    el = document.createElement('div')
    el.id = 'sw-copy-toast'
    el.setAttribute('role', 'status')
    document.body.appendChild(el)
  }
  el.textContent = msg
  el.classList.add('show')
  clearTimeout((el as any)._t)
  ;(el as any)._t = setTimeout(() => el!.classList.remove('show'), 1400)
}

async function copyText(text: string) {
  try {
    await navigator.clipboard.writeText(text)
  } catch {
    const t = document.createElement('textarea')
    t.value = text
    t.style.position = 'fixed'
    t.style.opacity = '0'
    document.body.appendChild(t)
    t.select()
    try {
      document.execCommand('copy')
    } catch {}
    t.remove()
  }
}

const linkFor = (hash: string) => `${location.origin}${location.pathname}#${hash}`

function decorate() {
  const doc =
    document.querySelector('.vp-doc') ||
    document.querySelector('main') ||
    document.querySelector('.content')
  if (!doc) return

  // Headings — click to copy a deep link (guard against text selection).
  doc
    .querySelectorAll<HTMLElement>('h1[id],h2[id],h3[id],h4[id],h5[id],h6[id]')
    .forEach((h) => {
      if (h.dataset.swLinked) return
      h.dataset.swLinked = '1'
      const id = h.id
      const fire = (e: Event) => {
        e.preventDefault()
        copyText(linkFor(id))
        history.replaceState(null, '', '#' + id)
        toast('Link copied')
      }
      h.querySelector<HTMLElement>('.header-anchor')?.addEventListener('click', fire)
      h.classList.add('sw-heading-link')
      h.addEventListener('click', (e) => {
        const t = e.target as HTMLElement
        if (t.closest('a:not(.header-anchor)')) return // a real link inside the heading
        if ((window.getSelection()?.toString() || '').length) return // user was selecting text
        fire(e)
      })
    })

  // Code blocks — assign a stable anchor + a copy-link button.
  let lastHeading = 'code'
  const counter: Record<string, number> = {}
  doc
    .querySelectorAll<HTMLElement>('h1[id],h2[id],h3[id],h4[id],div[class*="language-"]')
    .forEach((node) => {
      if (/^H[1-6]$/.test(node.tagName)) {
        lastHeading = node.id
        return
      }
      const block = node
      if (block.dataset.swLinked) return
      block.dataset.swLinked = '1'
      counter[lastHeading] = (counter[lastHeading] || 0) + 1
      const id = `${lastHeading}-code-${counter[lastHeading]}`
      block.id = id
      const btn = document.createElement('button')
      btn.className = 'copy-link'
      btn.title = 'Copy link to this code block'
      btn.setAttribute('aria-label', 'Copy link to this code block')
      btn.addEventListener('click', () => {
        copyText(linkFor(id))
        history.replaceState(null, '', '#' + id)
        toast('Code link copied')
      })
      block.appendChild(btn)
    })

  // Deep link into a code block: scroll to it + flash.
  const hash = decodeURIComponent(location.hash.slice(1))
  if (hash) {
    const target = document.getElementById(hash)
    if (target && target.matches('div[class*="language-"]')) {
      target.scrollIntoView({ block: 'center', behavior: 'smooth' })
      target.classList.add('sw-code-flash')
      setTimeout(() => target.classList.remove('sw-code-flash'), 1600)
    }
  }
}

export function setupDocLinks(router: Router) {
  if (typeof window === 'undefined') return
  const run = () => requestAnimationFrame(() => requestAnimationFrame(decorate))
  const orig = router.onAfterRouteChanged
  router.onAfterRouteChanged = (to) => {
    orig?.(to)
    run()
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', run)
  else run()
}
