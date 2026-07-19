<script setup lang="ts">
/**
 * Full-width Skript → SwoftLang mapping view.
 * Children must be <MappedPair> elements; each pair is one row with
 * the Skript source on the left and the SwoftLang equivalent on the right.
 */
withDefaults(
  defineProps<{
    /** Optional caption shown above the block */
    title?: string
    /** Column headings */
    leftLabel?: string
    rightLabel?: string
  }>(),
  { leftLabel: 'Skript', rightLabel: 'SwoftLang' }
)
</script>

<template>
  <figure class="mc">
    <figcaption v-if="title" class="mc-title">{{ title }}</figcaption>
    <div class="mc-head" aria-hidden="true">
      <span class="mc-head-left">{{ leftLabel }}</span>
      <span class="mc-head-right">{{ rightLabel }}</span>
    </div>
    <div class="mc-rows">
      <slot />
    </div>
  </figure>
</template>
