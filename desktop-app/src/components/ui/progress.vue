<script setup lang="ts">
import { computed } from 'vue'
import { cn } from '@/lib/utils'

const props = defineProps<{
  value?: number
  class?: string
}>()

const percentage = computed(() => Math.min(100, Math.max(0, props.value || 0)))
</script>

<template>
  <div :class="cn('relative h-4 w-full overflow-hidden rounded-full bg-secondary', $props.class)">
    <div
      class="h-full bg-primary transition-all duration-300"
      :style="{ width: `${percentage}%` }"
    />
  </div>
</template>
