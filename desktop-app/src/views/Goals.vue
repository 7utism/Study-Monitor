<template>
  <div>
    <h1 class="text-lg font-medium mb-6 text-[var(--text)]">学习目标</h1>

    <div class="grid grid-cols-2 gap-6">
      <!-- 进度 -->
      <div class="p-6 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="flex justify-between text-sm text-[var(--text-secondary)] mb-2">
          <span>今日进度</span>
          <span>{{ progressPercent.toFixed(0) }}%</span>
        </div>
        <div class="h-2 bg-[var(--border)] rounded-full overflow-hidden mb-4">
          <div class="h-full bg-[var(--text)] transition-all" :style="{ width: `${Math.min(100, progressPercent)}%` }"></div>
        </div>
        <div class="flex justify-between">
          <div>
            <div class="text-2xl font-medium text-[var(--text)]">{{ formatTime(todayStudied) }}</div>
            <div class="text-xs text-[var(--text-muted)]">已学习</div>
          </div>
          <div class="text-right">
            <div class="text-2xl font-medium text-[var(--text-secondary)]">{{ formatTime(dailyGoal) }}</div>
            <div class="text-xs text-[var(--text-muted)]">目标</div>
          </div>
        </div>
        <div v-if="progressPercent >= 100" class="mt-4 text-center text-sm text-[var(--text-secondary)]">✓ 今日目标已完成</div>
      </div>

      <!-- 设置 -->
      <div class="p-6 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-sm text-[var(--text-secondary)] mb-4">每日目标</div>
        <form @submit.prevent="saveGoal" class="flex items-center gap-3">
          <input v-model.number="goalHours" type="number" min="0" max="23" class="input w-16 text-center" />
          <span class="text-[var(--text-muted)]">时</span>
          <input v-model.number="goalMinutes" type="number" min="0" max="59" class="input w-16 text-center" />
          <span class="text-[var(--text-muted)]">分</span>
          <button type="submit" class="btn ml-auto">保存</button>
        </form>
      </div>
    </div>

    <!-- 状态 -->
    <div class="mt-6 p-6 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
      <div class="text-sm text-[var(--text-secondary)] mb-4">当前状态</div>
      <div v-if="currentSession" class="flex items-center gap-3">
        <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
        <span class="text-[var(--text)]">{{ currentSession.course_name }}</span>
        <span class="text-[var(--text-muted)]">·</span>
        <span class="text-[var(--text-secondary)]">{{ formatTime(currentSession.duration) }}</span>
      </div>
      <div v-else class="text-[var(--text-muted)]">未在学习</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { invoke } from '@tauri-apps/api/tauri'

const dailyGoal = ref(0)
const todayStudied = ref(0)
const goalHours = ref(2)
const goalMinutes = ref(0)
const currentSession = ref<{ course_name: string; duration: number } | null>(null)

const progressPercent = computed(() => dailyGoal.value ? (todayStudied.value / dailyGoal.value) * 100 : 0)

const formatTime = (s: number) => {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

const loadData = async () => {
  try {
    const [goal, studied, session] = await Promise.all([
      invoke<number>('get_daily_goal'),
      invoke<number>('get_today_studied'),
      invoke<{ course_name: string; duration: number } | null>('get_current_session')
    ])
    dailyGoal.value = goal
    todayStudied.value = studied
    currentSession.value = session
    
    // 只在首次加载或目标未设置时更新输入框
    if (goalHours.value === 2 && goalMinutes.value === 0 && goal > 0) {
      goalHours.value = Math.floor(goal / 3600)
      goalMinutes.value = Math.floor((goal % 3600) / 60)
    }
  } catch (e) {
    console.error('加载数据失败:', e)
  }
}

const saveGoal = async () => {
  const seconds = goalHours.value * 3600 + goalMinutes.value * 60
  await invoke('set_daily_goal', { seconds })
  dailyGoal.value = seconds
}

let timer: number
onMounted(() => {
  loadData()
  timer = window.setInterval(loadData, 2000) // 2秒刷新一次
})
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.input {
  @apply px-3 py-2 bg-[var(--bg)] border border-[var(--border)] rounded text-[var(--text)] text-sm outline-none transition-colors;
}
.input:focus {
  border-color: var(--text-secondary);
}
.btn {
  @apply px-4 py-2 bg-[var(--btn-bg)] text-[var(--btn-text)] text-sm font-medium rounded transition-colors flex items-center justify-center leading-none;
}
.btn:hover {
  background: var(--btn-hover);
}
</style>
