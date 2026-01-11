<template>
  <div class="flex h-screen bg-[var(--bg)]">
    <aside class="w-52 flex flex-col bg-[var(--bg-secondary)] shadow-lg">
      <div class="p-5 flex items-center justify-between">
        <span class="text-base font-medium text-[var(--text)]">Study Monitor</span>
        <button @click="toggle" class="p-2 rounded-lg hover:bg-[var(--bg-tertiary)] transition-colors" title="切换主题">
          <svg v-if="isDark" class="w-4 h-4 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
          </svg>
          <svg v-else class="w-4 h-4 text-[var(--text-secondary)]" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
          </svg>
        </button>
      </div>
      <nav class="flex-1 px-3 py-2 space-y-1">
        <router-link
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          class="block px-4 py-2.5 rounded-lg text-[var(--text-secondary)] hover:text-[var(--text)] hover:bg-[var(--bg-tertiary)] transition-all text-sm"
          active-class="!text-[var(--text)] !bg-[var(--bg-tertiary)] shadow-sm"
        >
          {{ item.label }}
        </router-link>
      </nav>
      <div class="m-3 p-4 rounded-lg bg-[var(--bg)]">
        <div class="text-xs text-[var(--text-muted)] mb-1">今日学习</div>
        <div class="text-xl font-medium text-[var(--text)]">{{ formatTime(todayStudied) }}</div>
      </div>
    </aside>
    <main class="flex-1 overflow-auto p-6">
      <router-view />
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { invoke } from '@tauri-apps/api/tauri'
import { fetch as tauriFetch, Body, ResponseType } from '@tauri-apps/api/http'
import { listen, UnlistenFn } from '@tauri-apps/api/event'
import { useTheme } from './composables/useTheme'

const { isDark, toggle } = useTheme()

const navItems = [
  { path: '/dashboard', label: '仪表盘' },
  { path: '/courses', label: '课程' },
  { path: '/goals', label: '目标' },
  { path: '/statistics', label: '统计' },
  { path: '/sync', label: '同步' },
]

const todayStudied = ref(0)

function formatTime(s: number): string {
  const h = Math.floor(s / 3600)
  const m = Math.floor((s % 3600) / 60)
  return h > 0 ? `${h}h ${m}m` : `${m}m`
}

async function load() {
  todayStudied.value = await invoke('get_today_studied')
}

// 全局自动同步逻辑
let autoSyncTimer: number | null = null
let pauseSyncUnlisten: UnlistenFn | null = null

async function doSync() {
  try {
    const [syncUrl, userId] = await invoke<[string | null, string | null]>('get_sync_config')
    if (!syncUrl || !userId) return
    
    const data = await invoke<any>('get_sync_data')
    await tauriFetch(`${syncUrl}/api/sync`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: Body.json({ userId, ...data }),
      responseType: ResponseType.JSON
    })
    console.log('Auto sync completed')
  } catch (e) {
    console.error('Auto sync failed:', e)
  }
}

async function initAutoSync() {
  const [autoSyncEnabled, autoSyncInterval, syncOnPause] = await invoke<[boolean, number, boolean]>('get_auto_sync_config')
  
  // 清除旧定时器
  if (autoSyncTimer) {
    clearInterval(autoSyncTimer)
    autoSyncTimer = null
  }
  
  // 定时同步
  if (autoSyncEnabled) {
    autoSyncTimer = window.setInterval(doSync, autoSyncInterval * 1000)
  }
  
  // 暂停时同步 - 监听事件
  if (pauseSyncUnlisten) {
    pauseSyncUnlisten()
  }
  pauseSyncUnlisten = await listen('sync-on-pause', () => {
    console.log('Received sync-on-pause event')
    doSync()
  })
}

let timer: number
onMounted(() => {
  load()
  timer = window.setInterval(load, 5000)
  initAutoSync()
  
  // 监听配置变更事件
  window.addEventListener('reinit-auto-sync', initAutoSync)
})

onUnmounted(() => {
  clearInterval(timer)
  if (autoSyncTimer) clearInterval(autoSyncTimer)
  if (pauseSyncUnlisten) pauseSyncUnlisten()
  window.removeEventListener('reinit-auto-sync', initAutoSync)
})
</script>
