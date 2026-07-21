<script setup lang="ts">
import { onMounted } from 'vue'
import { dialect, setDialect, hydrateDialect } from './dialect'

/**
 * One worked example shown in two coexisting dialects. Fill the #natural slot
 * with the natural-language variant and the #code slot with the method-form
 * variant — both are fenced ```swoftlang blocks that compile to the same thing.
 * The header switch flips this and every other <DialectCode> on the page at
 * once (shared, localStorage-persisted state).
 *
 * Both slots stay in the DOM (toggled with v-show) so server and client render
 * identically and the docs snippet sweep type-checks both variants.
 */
withDefaults(
  defineProps<{
    /** Optional caption above the panel, e.g. "Look up a price" */
    title?: string
    /** Optional filename chip, e.g. "prices.sw" */
    file?: string
  }>(),
  {}
)

onMounted(hydrateDialect)
</script>

<template>
  <figure class="dc">
    <figcaption class="dc-head">
      <span class="dc-meta">
        <span v-if="title" class="dc-title">{{ title }}</span>
        <span v-if="file" class="dc-file">{{ file }}</span>
      </span>
      <div class="dc-switch" role="group" aria-label="Choose collection dialect">
        <button
          :class="{ on: dialect === 'natural' }"
          :aria-pressed="dialect === 'natural'"
          @click="setDialect('natural')"
        >
          Natural Language
        </button>
        <button
          :class="{ on: dialect === 'code' }"
          :aria-pressed="dialect === 'code'"
          @click="setDialect('code')"
        >
          Code
        </button>
      </div>
    </figcaption>

    <div v-show="dialect === 'natural'" class="dc-pane">
      <slot name="natural" />
    </div>
    <div v-show="dialect === 'code'" class="dc-pane">
      <slot name="code" />
    </div>
  </figure>
</template>
