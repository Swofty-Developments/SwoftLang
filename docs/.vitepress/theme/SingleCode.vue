<script setup lang="ts">
/**
 * Single-language variant of the mapping chrome: one full-width
 * SwoftLang (or any) code panel with a label chip and optional filename.
 */
withDefaults(
  defineProps<{
    /** Chip text, e.g. "SwoftLang" */
    label?: string
    /** Optional filename shown next to the chip, e.g. "warp.sw" */
    file?: string
  }>(),
  { label: 'SwoftLang' }
)
</script>

<template>
  <figure class="sc">
    <figcaption class="sc-head">
      <span class="sc-chip">{{ label }}</span>
      <span v-if="file" class="sc-file">{{ file }}</span>
    </figcaption>
    <div class="sc-body">
      <slot />
    </div>
  </figure>
</template>
