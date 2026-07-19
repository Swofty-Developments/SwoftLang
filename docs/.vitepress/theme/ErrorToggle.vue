<script setup lang="ts">
import { ref } from 'vue'

/**
 * A code panel with two states: the broken program plus the real
 * `swoftc check` diagnostic, and the fixed program that compiles clean.
 * All three slots (#broken, #fixed, #error) take fenced code blocks.
 */
withDefaults(
  defineProps<{
    /** Filename shown in the chrome, e.g. "warp.sw" */
    file?: string
    /** Extra text after the ✓ when showing the fixed variant */
    okText?: string
    /** Note appended under the diagnostic, e.g. "+ 7 more errors" */
    errorNote?: string
  }>(),
  { file: 'script.sw', okText: 'swoftc check — no errors. Ship it.' }
)

const fixed = ref(false)
</script>

<template>
  <div class="et" :class="fixed ? 'is-fixed' : 'is-broken'">
    <div class="et-bar">
      <span class="et-file">{{ file }}</span>
      <div class="et-switch" role="group" aria-label="Toggle broken or fixed variant">
        <button :class="{ on: !fixed }" @click="fixed = false">broken</button>
        <button :class="{ on: fixed }" @click="fixed = true">fixed</button>
      </div>
    </div>

    <div v-show="!fixed" class="et-pane">
      <slot name="broken" />
      <div class="et-diag">
        <p class="et-diag-title">
          <span class="et-dot" aria-hidden="true"></span>
          swoftc check {{ file }} — real compiler output
        </p>
        <slot name="error" />
        <p v-if="errorNote" class="et-diag-note">{{ errorNote }}</p>
      </div>
    </div>

    <div v-show="fixed" class="et-pane">
      <slot name="fixed" />
      <p class="et-ok"><span aria-hidden="true">✓</span> {{ okText }}</p>
    </div>
  </div>
</template>
