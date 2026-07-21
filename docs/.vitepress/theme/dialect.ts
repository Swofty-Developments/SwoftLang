import { ref } from 'vue'

/**
 * Shared per-visitor collection-dialect preference, synced across every
 * <DialectCode> and <DialectSwitch> on the page and persisted in localStorage.
 *
 * SSR-safe: the ref always initialises to 'natural' so the server-rendered
 * markup matches the first client render (no hydration mismatch). The stored
 * preference is applied in onMounted by the components (see hydrateDialect).
 */
export type Dialect = 'natural' | 'code'

const KEY = 'swoftlang-dialect'

export const dialect = ref<Dialect>('natural')

let hydrated = false

/** Apply the persisted choice once, after mount. Safe to call from every instance. */
export function hydrateDialect() {
  if (hydrated || typeof window === 'undefined') return
  hydrated = true
  try {
    const saved = window.localStorage.getItem(KEY)
    if (saved === 'natural' || saved === 'code') dialect.value = saved
  } catch {
    /* localStorage may be unavailable (private mode) — ignore */
  }
}

export function setDialect(d: Dialect) {
  dialect.value = d
  if (typeof window === 'undefined') return
  try {
    window.localStorage.setItem(KEY, d)
  } catch {
    /* ignore */
  }
}
