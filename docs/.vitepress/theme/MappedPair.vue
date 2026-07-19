<script setup lang="ts">
import { useSlots } from 'vue'

/**
 * One mapping row inside <MappedCompare>: Skript on the left,
 * SwoftLang on the right, a left-aligned pair label, and an
 * optional collapsible note underneath.
 */
defineProps<{
  /** Pair label, e.g. "join event" */
  label: string
}>()

const slots = useSlots()
</script>

<template>
  <section class="mc-pair">
    <div class="mc-label">{{ label }}</div>
    <div class="mc-grid">
      <div class="mc-cell mc-cell-skript">
        <slot name="skript" />
      </div>
      <div class="mc-cell mc-cell-swoftlang">
        <slot name="swoftlang" />
      </div>
    </div>
    <details v-if="slots.note" class="mc-note">
      <summary>Why it maps this way</summary>
      <div class="mc-note-body">
        <slot name="note" />
      </div>
    </details>
  </section>
</template>
