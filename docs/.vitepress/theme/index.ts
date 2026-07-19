import type { Theme } from 'vitepress'
import Layout from './Layout.vue'

import MappedCompare from './MappedCompare.vue'
import MappedPair from './MappedPair.vue'
import SingleCode from './SingleCode.vue'
import StepHeader from './StepHeader.vue'
import ErrorToggle from './ErrorToggle.vue'

// self-hosted fonts (no runtime external fetches)
import '@fontsource-variable/bricolage-grotesque'
import '@fontsource-variable/schibsted-grotesk'
import '@fontsource-variable/red-hat-mono'

import './custom.css'
import './layout.css'
import './components.css'

export default {
  Layout,
  enhanceApp({ app }) {
    app.component('MappedCompare', MappedCompare)
    app.component('MappedPair', MappedPair)
    app.component('SingleCode', SingleCode)
    app.component('StepHeader', StepHeader)
    app.component('ErrorToggle', ErrorToggle)
  }
} satisfies Theme
