<script setup lang="ts">
import { computed } from 'vue'
import { useData } from 'vitepress'
import { findStep, normalizePath } from './steps'

/**
 * Large numbered header for guide steps. If `n`/`title` are omitted
 * they are derived from the guide step registry (steps.ts) by route.
 */
const props = defineProps<{
  n?: number | string
  title?: string
}>()

const { page } = useData()

const derived = computed(() =>
  findStep('/' + normalizePath(page.value.relativePath.replace(/\.md$/, '')))
)
const num = computed(() => {
  const v = props.n ?? derived.value?.n
  return v != null ? String(v).padStart(2, '0') : ''
})
const heading = computed(() => props.title ?? derived.value?.title ?? '')
</script>

<template>
  <header class="step-head">
    <div class="step-num" aria-hidden="true">{{ num }}</div>
    <div class="step-meta">
      <p class="step-kicker">Guide · Step {{ num }}</p>
      <h1 class="step-title">{{ heading }}</h1>
      <div class="step-build">
        <span class="step-build-label">You'll build</span>
        <span class="step-build-text"><slot /></span>
      </div>
    </div>
  </header>
</template>
