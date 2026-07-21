<script setup lang="ts">
import { computed, defineAsyncComponent, onMounted, onUnmounted, ref, watch } from 'vue'
import { useData, useRoute, inBrowser } from 'vitepress'
import { findStep, guideSteps, normalizePath } from './steps'
import {
  sidebarForPath,
  versionForPath,
  versions,
  type NavGroup
} from './nav'

const { isDark, page, frontmatter } = useData()
const route = useRoute()

/* ---------- versioning ---------- */

// which docs version the current route belongs to (root/latest by default)
const version = computed(() => versionForPath(route.path))
// route prefix to keep the top-bar sections inside the active version
const versionBase = computed(() => version.value.prefix)
const verOpen = ref(false)
const verSwitch = ref<HTMLElement | null>(null)

// close the version menu on an outside click or Escape (no overlay — an overlay
// would sit above the sticky top-bar's stacking context and swallow item clicks)
function onDocPointer(e: MouseEvent) {
  if (verOpen.value && verSwitch.value && !verSwitch.value.contains(e.target as Node)) {
    verOpen.value = false
  }
}
function onDocKey(e: KeyboardEvent) {
  if (e.key === 'Escape') verOpen.value = false
}
onMounted(() => {
  document.addEventListener('click', onDocPointer)
  document.addEventListener('keydown', onDocKey)
})
onUnmounted(() => {
  document.removeEventListener('click', onDocPointer)
  document.removeEventListener('keydown', onDocKey)
})

/* ---------- top-bar sections (version-aware) ---------- */

const baseSections = [
  { text: 'Guide', path: '/guide/' },
  { text: 'Reference', path: '/reference/' },
  { text: 'Libraries', path: '/libraries/' },
  { text: 'Examples', path: '/examples/' }
]

const sections = computed(() =>
  baseSections.map((s) => {
    const link = versionBase.value + s.path
    return { text: s.text, link, match: new RegExp('^' + link.replace(/[.]/g, '\\.')) }
  })
)

const isHome = computed(() => frontmatter.value.layout === 'home')
const isActive = (m: RegExp) => m.test(route.path)

/* ---------- left sidebar (persistent grouped tree, version-aware) ---------- */

const sidebar = computed<NavGroup[]>(() => sidebarForPath(route.path))

const currentPath = computed(() => normalizePath(route.path))
const isCurrent = (link: string) => normalizePath(link) === currentPath.value

const activeGroup = computed<NavGroup | undefined>(() =>
  sidebar.value.find((g) => g.match.test(route.path))
)

// which groups are expanded; the active group opens, others collapse (toggleable)
const openGroups = ref<Record<string, boolean>>({})
const isGroupOpen = (text: string) => !!openGroups.value[text]
function toggleGroup(text: string) {
  openGroups.value = { ...openGroups.value, [text]: !openGroups.value[text] }
}

// mobile off-canvas drawer
const drawerOpen = ref(false)

watch(
  () => route.path,
  () => {
    const g = activeGroup.value
    if (g) openGroups.value = { ...openGroups.value, [g.text]: true }
    drawerOpen.value = false
    verOpen.value = false
  },
  { immediate: true }
)

/* ---------- theme toggle ---------- */

function toggleDark() {
  isDark.value = !isDark.value
}

/* ---------- search ---------- */

const SearchBox = defineAsyncComponent(
  () => import('vitepress/dist/client/theme-default/components/VPLocalSearchBox.vue')
)
const showSearch = ref(false)
const searchLoaded = ref(false)

function openSearch() {
  searchLoaded.value = true
  showSearch.value = true
}

function onKeydown(e: KeyboardEvent) {
  const el = e.target as HTMLElement
  const typing =
    el?.isContentEditable || ['input', 'textarea', 'select'].includes(el?.tagName?.toLowerCase())
  if ((e.key === 'k' || e.key === 'K') && (e.metaKey || e.ctrlKey)) {
    e.preventDefault()
    showSearch.value ? (showSearch.value = false) : openSearch()
  } else if (e.key === '/' && !typing && !showSearch.value) {
    e.preventDefault()
    openSearch()
  }
}

const isMac = ref(false)

onMounted(() => {
  window.addEventListener('keydown', onKeydown)
  isMac.value = /Mac|iPhone|iPad/.test(navigator.platform)
})
onUnmounted(() => {
  if (inBrowser) window.removeEventListener('keydown', onKeydown)
})

/* ---------- guide step prev/next ---------- */

const currentStep = computed(() =>
  findStep('/' + normalizePath(page.value.relativePath.replace(/\.md$/, '')))
)
const prevStep = computed(() =>
  currentStep.value ? guideSteps.find((s) => s.n === currentStep.value!.n - 1) : undefined
)
const nextStep = computed(() =>
  currentStep.value ? guideSteps.find((s) => s.n === currentStep.value!.n + 1) : undefined
)
</script>

<template>
  <div class="sw-shell" :class="{ 'is-home': isHome }">
    <a class="sw-skip" href="#sw-main">Skip to content</a>

    <header class="sw-topbar">
      <div class="sw-topbar-inner">
        <button
          v-if="!isHome"
          class="sw-icon-btn sw-burger"
          :aria-expanded="drawerOpen"
          aria-label="Toggle navigation"
          @click="drawerOpen = !drawerOpen"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
            <path d="M4 7h16M4 12h16M4 17h16" />
          </svg>
        </button>

        <a href="/" class="sw-wordmark" aria-label="SwoftLang home">
          <span class="sw-mark" aria-hidden="true">sw</span>
          <span class="sw-name">SwoftLang</span>
        </a>

        <nav class="sw-nav" aria-label="Sections">
          <a
            v-for="s in sections"
            :key="s.link"
            :href="s.link"
            class="sw-nav-link"
            :class="{ active: isActive(s.match) }"
            >{{ s.text }}</a
          >
        </nav>

        <div class="sw-tools">
          <div class="sw-verswitch" ref="verSwitch">
            <button
              class="sw-ver-btn"
              :aria-expanded="verOpen"
              aria-label="Select docs version"
              @click.stop="verOpen = !verOpen"
            >
              <span class="sw-ver-label">{{ version.label }}</span>
              <svg class="sw-ver-chev" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="m6 9 6 6 6-6" />
              </svg>
            </button>
            <ul v-show="verOpen" class="sw-ver-menu" role="menu">
              <li v-for="v in versions" :key="v.link" role="none">
                <a
                  role="menuitem"
                  :href="v.link"
                  class="sw-ver-item"
                  :class="{ current: v.prefix === version.prefix }"
                >{{ v.text }}</a>
              </li>
            </ul>
          </div>

          <button class="sw-search-btn" aria-label="Search docs" @click="openSearch">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
              <circle cx="11" cy="11" r="7" />
              <path d="m21 21-4.3-4.3" />
            </svg>
            <span class="sw-search-label">Search</span>
            <kbd class="sw-kbd">{{ isMac ? '⌘' : 'Ctrl' }} K</kbd>
          </button>

          <button class="sw-icon-btn" aria-label="Toggle color theme" @click="toggleDark">
            <!-- both icons rendered; CSS picks one by html.dark to stay SSR-safe -->
            <svg class="sw-ico-sun" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" aria-hidden="true">
              <circle cx="12" cy="12" r="4" />
              <path d="M12 2v2m0 16v2M4.9 4.9l1.4 1.4m11.4 11.4 1.4 1.4M2 12h2m16 0h2M4.9 19.1l1.4-1.4m11.4-11.4 1.4-1.4" />
            </svg>
            <svg class="sw-ico-moon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" />
            </svg>
          </button>
        </div>
      </div>
    </header>

    <!-- 404 -->
    <main v-if="page.isNotFound" id="sw-main" class="sw-notfound">
      <p class="sw-notfound-code">404</p>
      <h1>This page fell off the end of a function.</h1>
      <p>Its inferred type is <code>optional&lt;Page&gt;</code> — and it's <code>none</code>.</p>
      <a href="/" class="sw-notfound-link">sw-docs otherwise home →</a>
    </main>

    <!-- home -->
    <main v-else-if="isHome" id="sw-main" class="sw-home sw-enter">
      <Content class="sw-doc" />
    </main>

    <!-- doc page: persistent left sidebar + wide article -->
    <div v-else class="sw-page">
      <div
        class="sw-side-backdrop"
        :class="{ show: drawerOpen }"
        aria-hidden="true"
        @click="drawerOpen = false"
      />

      <aside class="sw-sidebar" :class="{ open: drawerOpen }" aria-label="Documentation">
        <nav class="sw-side-scroll">
          <div
            v-for="g in sidebar"
            :key="g.text"
            class="sw-side-group"
            :class="{ open: isGroupOpen(g.text), active: g === activeGroup }"
          >
            <button
              class="sw-side-grouphead"
              :aria-expanded="isGroupOpen(g.text)"
              @click="toggleGroup(g.text)"
            >
              <span class="sw-side-grouptext">{{ g.text }}</span>
              <svg class="sw-side-chev" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                <path d="m9 18 6-6-6-6" />
              </svg>
            </button>

            <div v-show="isGroupOpen(g.text)" class="sw-side-body">
              <ul v-if="g.items" class="sw-side-list">
                <li v-for="it in g.items" :key="it.link">
                  <a
                    :href="it.link"
                    class="sw-side-link"
                    :class="{ current: isCurrent(it.link) }"
                    :aria-current="isCurrent(it.link) ? 'page' : undefined"
                  >
                    <span v-if="it.num" class="sw-side-num" aria-hidden="true">{{ it.num }}</span>
                    <span class="sw-side-linktext">{{ it.text }}</span>
                  </a>
                </li>
              </ul>

              <div v-for="sg in g.subgroups" :key="sg.text" class="sw-side-sub">
                <p class="sw-side-subhead">{{ sg.text }}</p>
                <ul class="sw-side-list">
                  <li v-for="it in sg.items" :key="it.link">
                    <a
                      :href="it.link"
                      class="sw-side-link"
                      :class="{ current: isCurrent(it.link) }"
                      :aria-current="isCurrent(it.link) ? 'page' : undefined"
                    >
                      <span class="sw-side-linktext">{{ it.text }}</span>
                    </a>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </nav>
      </aside>

      <main id="sw-main" class="sw-article sw-enter">
        <Content class="sw-doc" />

        <nav v-if="currentStep" class="sw-stepnav" aria-label="Guide steps">
          <a v-if="prevStep" class="sw-stepnav-link prev" :href="prevStep.path">
            <span class="sw-stepnav-kicker">← Step {{ String(prevStep.n).padStart(2, '0') }}</span>
            <span class="sw-stepnav-title">{{ prevStep.title }}</span>
          </a>
          <span v-else class="sw-stepnav-spacer" />
          <a v-if="nextStep" class="sw-stepnav-link next" :href="nextStep.path">
            <span class="sw-stepnav-kicker">Step {{ String(nextStep.n).padStart(2, '0') }} →</span>
            <span class="sw-stepnav-title">{{ nextStep.title }}</span>
          </a>
        </nav>
      </main>
    </div>

    <footer class="sw-footer">
      <div class="sw-footer-inner">
        <p>
          <strong>SwoftLang</strong> — compiled by OCaml, executed on the JVM.
        </p>
        <p>
          <a href="/guide/">Start the guide</a> ·
          <a href="/reference/syntax-cheatsheet">Cheatsheet</a> ·
          <a href="/reference/">Reference</a>
        </p>
      </div>
    </footer>


    <SearchBox v-if="searchLoaded && showSearch" @close="showSearch = false" />
  </div>
</template>
