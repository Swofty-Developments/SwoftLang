<script setup lang="ts">
import { onMounted } from 'vue'
import { dialect, setDialect, hydrateDialect } from './dialect'

/**
 * Page-level segmented control that flips every <DialectCode> on the page
 * between the natural-language and method (code) dialect. Drop one near the
 * top of a page; the choice is shared and persisted across all examples.
 */
onMounted(hydrateDialect)
</script>

<template>
  <div class="dsw" role="group" aria-label="Choose collection dialect">
    <span class="dsw-label">Dialect</span>
    <div class="dsw-switch">
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
  </div>
</template>
