<template>
  <div>
    <h1 class="text-lg font-medium mb-6 text-[var(--text)]">学习统计</h1>

    <!-- 筛选 -->
    <div class="flex items-center gap-3 mb-6">
      <input v-model="startDate" type="date" @change="loadStats" class="input" />
      <span class="text-[var(--text-muted)]">—</span>
      <input v-model="endDate" type="date" @change="loadStats" class="input" />
      <select v-model="selectedSubject" @change="loadStats" class="input min-w-[120px]">
        <option value="">全部科目</option>
        <option v-for="s in subjects" :key="s" :value="s">{{ s }}</option>
      </select>
    </div>

    <!-- 总览 -->
    <div class="grid grid-cols-4 gap-4 mb-6">
      <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-2xl font-medium text-[var(--text)]">{{ formatTime(totalTime) }}</div>
        <div class="text-xs text-[var(--text-muted)]">总时长</div>
      </div>
      <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-2xl font-medium text-[var(--text)]">{{ totalDays }}</div>
        <div class="text-xs text-[var(--text-muted)]">学习天数</div>
      </div>
      <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-2xl font-medium text-[var(--text)]">{{ streak }}</div>
        <div class="text-xs text-[var(--text-muted)]">连续学习</div>
      </div>
      <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-2xl font-medium text-[var(--text)]">{{ formatTime(avgDaily) }}</div>
        <div class="text-xs text-[var(--text-muted)]">日均</div>
      </div>
    </div>

    <div class="grid grid-cols-2 gap-6">
      <!-- 课程 -->
      <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-sm text-[var(--text-secondary)] mb-4">按课程</div>
        <div class="space-y-3">
          <div v-for="stat in courseStats" :key="stat.course_id">
            <div class="flex justify-between text-sm mb-1">
              <span class="text-[var(--text)]">{{ stat.course_name }}</span>
              <span class="text-[var(--text-muted)]">{{ formatTime(stat.duration) }}</span>
            </div>
            <div class="h-1 bg-[var(--border)] rounded-full">
              <div class="h-full bg-[var(--text)] rounded-full" :style="{ width: `${stat.percent}%` }"></div>
            </div>
          </div>
          <div v-if="!courseStats.length" class="text-center py-8 text-[var(--text-muted)]">暂无数据</div>
        </div>
      </div>

      <!-- 日期 -->
      <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-sm text-[var(--text-secondary)] mb-4">按日期</div>
        <div class="space-y-2 max-h-64 overflow-auto">
          <div v-for="stat in dailyStats" :key="stat.date" class="flex items-center justify-between text-sm py-1">
            <span class="text-[var(--text)]">{{ stat.date }}</span>
            <div class="flex items-center gap-3">
              <span class="text-[var(--text-secondary)]">{{ formatTime(stat.duration) }}</span>
              <span :class="stat.goal_met ? 'text-green-500' : 'text-[var(--text-muted)]'">{{ stat.goal_met ? '✓' : '—' }}</span>
            </div>
          </div>
          <div v-if="!dailyStats.length" class="text-center py-8 text-[var(--text-muted)]">暂无数据</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { invoke } from '@tauri-apps/api/tauri'

interface CourseStat { course_id: string; course_name: string; subject: string; duration: number; percent: number }
interface DailyStat { date: string; duration: number; goal_met: boolean }

const startDate = ref('')
const endDate = ref('')
const selectedSubject = ref('')
const subjects = ref<string[]>([])
const courseStats = ref<CourseStat[]>([])
const dailyStats = ref<DailyStat[]>([])

const totalTime = computed(() => courseStats.value.reduce((s, c) => s + c.duration, 0))
const totalDays = computed(() => dailyStats.value.length)
const avgDaily = computed(() => totalDays.value ? Math.round(totalTime.value / totalDays.value) : 0)
const streak = computed(() => {
  // 从今天往前数连续达标的天数
  const today = new Date().toISOString().split('T')[0]
  const sorted = [...dailyStats.value].sort((a, b) => b.date.localeCompare(a.date))
  let count = 0
  let checkDate = new Date()
  
  for (let i = 0; i < 365; i++) {
    const dateStr = checkDate.toISOString().split('T')[0]
    const stat = sorted.find(s => s.date === dateStr)
    if (stat && stat.goal_met) {
      count++
      checkDate.setDate(checkDate.getDate() - 1)
    } else if (dateStr === today && !stat) {
      // 今天还没学习，从昨天开始算
      checkDate.setDate(checkDate.getDate() - 1)
    } else {
      break
    }
  }
  return count
})

const formatTime = (s: number) => {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

const loadStats = async () => {
  try {
    const r = await invoke<{ subjects: string[]; course_stats: CourseStat[]; daily_stats: DailyStat[] }>('get_statistics', {
      startDate: startDate.value || null,
      endDate: endDate.value || null,
      subject: selectedSubject.value || null,
    })
    subjects.value = r.subjects
    courseStats.value = r.course_stats
    dailyStats.value = r.daily_stats
  } catch (e) {
    console.error('加载统计失败:', e)
  }
}

const initDates = () => {
  const today = new Date()
  const weekAgo = new Date(today.getTime() - 7 * 86400000)
  endDate.value = today.toISOString().split('T')[0]
  startDate.value = weekAgo.toISOString().split('T')[0]
}

let timer: number
onMounted(() => {
  initDates()
  loadStats()
  timer = window.setInterval(loadStats, 5000) // 5秒刷新一次
})
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.input {
  @apply px-3 py-2 bg-[var(--bg)] border border-[var(--border)] rounded text-[var(--text)] text-sm outline-none cursor-pointer transition-colors;
}
.input:focus {
  border-color: var(--text-secondary);
}
</style>
