import type { Theme } from 'vitepress'
import Layout from './Layout.vue'

import MappedCompare from './MappedCompare.vue'
import MappedPair from './MappedPair.vue'
import SingleCode from './SingleCode.vue'
import StepHeader from './StepHeader.vue'
import ErrorToggle from './ErrorToggle.vue'
import DialectCode from './DialectCode.vue'
import DialectSwitch from './DialectSwitch.vue'

// self-hosted fonts (no runtime external fetches)
import '@fontsource-variable/bricolage-grotesque'
import '@fontsource-variable/schibsted-grotesk'
import '@fontsource-variable/red-hat-mono'

import './custom.css'
import './layout.css'
import './components.css'
import './anchors.css'

import { setupDocLinks } from './docLinks'

export default {
  Layout,
  enhanceApp({ app, router }) {
    setupDocLinks(router)
    app.component('MappedCompare', MappedCompare)
    app.component('MappedPair', MappedPair)
    app.component('SingleCode', SingleCode)
    app.component('StepHeader', StepHeader)
    app.component('ErrorToggle', ErrorToggle)
    app.component('DialectCode', DialectCode)
    app.component('DialectSwitch', DialectSwitch)
  }
} satisfies Theme
