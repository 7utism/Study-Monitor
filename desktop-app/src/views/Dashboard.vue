<template>
  <div class="h-full flex flex-col">
    <h1 class="text-lg font-medium mb-6 text-[var(--text)]">仪表盘</h1>

    <div class="grid grid-cols-3 gap-4 mb-6">
      <!-- 左侧：表情包 -->
      <div 
        class="row-span-2 p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)] flex items-center justify-center cursor-pointer select-none"
        @click="nextEmoji"
      >
        <img 
          :src="currentEmoji" 
          alt="表情包" 
          class="max-w-[120px] aspect-square object-contain transition-opacity duration-200"
          :class="{ 'opacity-0': isChanging }"
        />
      </div>

      <!-- 右侧上：今日数据 -->
      <div class="col-span-2 grid grid-cols-4 gap-4">
        <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
          <div class="text-xs text-[var(--text-muted)] mb-1">距离考试还有</div>
          <div class="text-xl font-medium text-[var(--text)] cursor-pointer" @click="showExamModal = true">
            {{ examDays !== null ? `${examDays} 天` : '未设置' }}
          </div>
        </div>
        <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
          <div class="text-xs text-[var(--text-muted)] mb-1">今日学习</div>
          <div class="text-xl font-medium text-[var(--text)]">{{ formatTime(todayStudied) }}</div>
        </div>
        <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
          <div class="text-xs text-[var(--text-muted)] mb-1">目标进度</div>
          <div class="text-xl font-medium text-[var(--text)]">{{ progressPercent.toFixed(0) }}%</div>
        </div>
        <div class="p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
          <div class="text-xs text-[var(--text-muted)] mb-1">本周总计</div>
          <div class="text-xl font-medium text-[var(--text)]">{{ formatTime(weekTotal) }}</div>
        </div>
      </div>

      <!-- 右侧下：目标进度条 -->
      <div class="col-span-2 p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="flex justify-between text-sm text-[var(--text-secondary)] mb-2">
          <span>今日目标</span>
          <span>{{ formatTime(todayStudied) }} / {{ formatTime(dailyGoal) }}</span>
        </div>
        <div class="h-3 bg-[var(--border)] rounded-full overflow-hidden">
          <div 
            class="h-full bg-[var(--text)] transition-all duration-300 rounded-full" 
            :style="{ width: `${Math.min(100, progressPercent)}%` }"
          ></div>
        </div>
        <div v-if="progressPercent >= 100" class="mt-2 text-center text-sm text-green-500">✓ 今日目标已完成！</div>
      </div>
    </div>

    <!-- 学习曲线图 -->
    <div class="flex-1 p-4 bg-[var(--bg-secondary)] rounded border border-[var(--border)] flex flex-col min-h-[200px]">
      <div class="flex justify-between items-center mb-2">
        <span class="text-sm text-[var(--text-secondary)]">本周学习时长</span>
        <div class="flex gap-2 flex-wrap">
          <span 
            v-for="(subj, idx) in courseStats" 
            :key="idx"
            class="text-xs px-2 py-0.5 rounded bg-[var(--border)] text-[var(--text-muted)]"
          >{{ subj.subject }}: {{ formatTimeShort(subj.duration) }}</span>
        </div>
      </div>
      <div class="flex-1">
        <Line ref="chartRef" :data="chartDataConfig" :options="chartOptions" :key="chartKey" />
      </div>
    </div>
  </div>

  <!-- 考试日期设置弹窗 -->
  <div v-if="showExamModal" class="fixed inset-0 bg-black/50 flex items-center justify-center z-50" @click.self="showExamModal = false">
    <div class="bg-[var(--bg-secondary)] p-6 rounded-lg border border-[var(--border)] w-80">
      <h3 class="text-base font-medium text-[var(--text)] mb-4">设置考试日期</h3>
      <input 
        type="date" 
        v-model="examDateInput"
        class="w-full px-3 py-2 rounded border border-[var(--border)] bg-[var(--bg)] text-[var(--text)] mb-4"
      />
      <div class="flex gap-2 justify-end">
        <button 
          @click="showExamModal = false"
          class="px-4 py-2 rounded border border-[var(--border)] text-[var(--text-secondary)] hover:bg-[var(--bg-tertiary)]"
        >取消</button>
        <button 
          @click="saveExamDate"
          class="px-4 py-2 rounded bg-[var(--text)] text-[var(--bg)] hover:opacity-80"
        >保存</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { invoke } from '@tauri-apps/api/tauri'
import { Line } from 'vue-chartjs'
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Filler,
} from 'chart.js'

ChartJS.register(CategoryScale, LinearScale, PointElement, LineElement, Title, Tooltip, Filler)

interface DailyStat { date: string; duration: number; goal_met: boolean }
interface CourseStat { course_id: string; course_name: string; subject: string; duration: number; percent: number }

const todayStudied = ref(0)
const dailyGoal = ref(0)
const weekStats = ref<DailyStat[]>([])
const courseStats = ref<CourseStat[]>([])

// 考试倒计时
const examDate = ref<string | null>(null)
const examDateInput = ref('')
const showExamModal = ref(false)
const examDays = computed(() => {
  if (!examDate.value) return null
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  const exam = new Date(examDate.value)
  const diff = Math.ceil((exam.getTime() - today.getTime()) / 86400000)
  return diff >= 0 ? diff : null
})

const saveExamDate = async () => {
  if (examDateInput.value) {
    await invoke('set_exam_date', { date: examDateInput.value })
    examDate.value = examDateInput.value
  }
  showExamModal.value = false
}

// 表情包相关
const emojiList = ['/emoji/1.png', '/emoji/2.png', '/emoji/3.png', '/emoji/4.png', '/emoji/5.png', '/emoji/6.png']
const currentEmojiIndex = ref(0)
const isChanging = ref(false)
const currentEmoji = computed(() => emojiList[currentEmojiIndex.value])

const nextEmoji = () => {
  isChanging.value = true
  setTimeout(() => {
    currentEmojiIndex.value = (currentEmojiIndex.value + 1) % emojiList.length
    isChanging.value = false
  }, 100)
}

const progressPercent = computed(() => dailyGoal.value ? (todayStudied.value / dailyGoal.value) * 100 : 0)
const weekTotal = computed(() => weekStats.value.reduce((sum, d) => sum + d.duration, 0))

// 图表 resize 处理
const chartRef = ref()
const chartKey = ref(0)

const handleResize = () => {
  // 强制重新渲染图表
  chartKey.value++
}

// 监听窗口大小变化和设备像素比变化
let resizeObserver: ResizeObserver | null = null
let lastPixelRatio = window.devicePixelRatio

const chartData = computed(() => {
  const today = new Date()
  const dayOfWeek = today.getDay()
  const monday = new Date(today)
  monday.setDate(today.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1))
  
  const days = []
  const labels = ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
  
  for (let i = 0; i < 7; i++) {
    const date = new Date(monday.getTime() + i * 86400000)
    const dateStr = date.toISOString().split('T')[0]
    const stat = weekStats.value.find(s => s.date === dateStr)
    const duration = stat?.duration || 0
    
    days.push({ label: labels[i], duration })
  }
  return days
})

const chartDataConfig = computed(() => ({
  labels: chartData.value.map(d => d.label),
  datasets: [{
    data: chartData.value.map(d => Math.round(d.duration / 60)), // 转换为分钟
    borderColor: 'rgb(100, 100, 100)',
    backgroundColor: 'rgba(100, 100, 100, 0.1)',
    fill: true,
    tension: 0.4,
    pointRadius: 5,
    pointHoverRadius: 7,
    pointBackgroundColor: 'rgb(100, 100, 100)',
    pointBorderColor: '#fff',
    pointBorderWidth: 2,
  }]
}))

const chartOptions = {
  responsive: true,
  maintainAspectRatio: false,
  plugins: {
    legend: { display: false },
    tooltip: {
      backgroundColor: 'rgba(0, 0, 0, 0.8)',
      titleFont: { size: 12 },
      bodyFont: { size: 12 },
      padding: 10,
      cornerRadius: 6,
      callbacks: {
        label: (ctx: any) => {
          const mins = ctx.raw
          const h = Math.floor(mins / 60)
          const m = mins % 60
          return h > 0 ? `${h}小时${m}分钟` : `${m}分钟`
        }
      }
    }
  },
  scales: {
    x: {
      grid: { display: false },
      ticks: { color: 'rgb(150, 150, 150)', font: { size: 11 } }
    },
    y: {
      beginAtZero: true,
      grid: { color: 'rgba(150, 150, 150, 0.1)' },
      ticks: {
        color: 'rgb(150, 150, 150)',
        font: { size: 11 },
        callback: (value: number) => {
          const h = Math.floor(value / 60)
          const m = value % 60
          return h > 0 ? `${h}h` : `${m}m`
        }
      }
    }
  },
  interaction: { intersect: false, mode: 'index' as const }
}

const formatTime = (s: number) => {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

const formatTimeShort = (s: number) => {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return h > 0 ? `${h}h` : `${m}m`
}

const loadData = async () => {
  try {
    const [goal, studied, savedExamDate] = await Promise.all([
      invoke<number>('get_daily_goal'),
      invoke<number>('get_today_studied'),
      invoke<string | null>('get_exam_date'),
    ])
    dailyGoal.value = goal
    todayStudied.value = studied
    examDate.value = savedExamDate
    if (savedExamDate) examDateInput.value = savedExamDate

    const today = new Date()
    const dayOfWeek = today.getDay()
    const monday = new Date(today)
    monday.setDate(today.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1))
    const sunday = new Date(monday.getTime() + 6 * 86400000)
    
    const stats = await invoke<{ daily_stats: DailyStat[]; course_stats: CourseStat[] }>('get_statistics', {
      startDate: monday.toISOString().split('T')[0],
      endDate: sunday.toISOString().split('T')[0],
      subject: null
    })
    weekStats.value = stats.daily_stats
    
    const subjectMap = new Map<string, number>()
    stats.course_stats.forEach(c => {
      subjectMap.set(c.subject, (subjectMap.get(c.subject) || 0) + c.duration)
    })
    courseStats.value = Array.from(subjectMap.entries()).map(([subject, duration]) => ({
      course_id: '', course_name: '', subject, duration, percent: 0
    }))
  } catch (e) {
    console.error('加载数据失败:', e)
  }
}

let emojiTimer: number
let dataTimer: number
let pixelRatioTimer: number

onMounted(() => {
  loadData()
  dataTimer = window.setInterval(loadData, 2000)
  emojiTimer = window.setInterval(nextEmoji, 10000)
  
  // 监听窗口 resize
  window.addEventListener('resize', handleResize)
  
  // 监听设备像素比变化（切换显示器时）
  pixelRatioTimer = window.setInterval(() => {
    if (window.devicePixelRatio !== lastPixelRatio) {
      lastPixelRatio = window.devicePixelRatio
      handleResize()
    }
  }, 500)
})

onUnmounted(() => {
  clearInterval(dataTimer)
  clearInterval(emojiTimer)
  clearInterval(pixelRatioTimer)
  window.removeEventListener('resize', handleResize)
})
</script>
