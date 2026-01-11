<template>
  <div>
    <h1 class="text-lg font-medium mb-6 text-[var(--text)]">云同步</h1>

    <div class="grid grid-cols-2 gap-6">
      <!-- 同步配置 -->
      <div class="p-6 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-sm text-[var(--text-secondary)] mb-4">同步配置</div>
        <div class="space-y-4">
          <div>
            <label class="block text-xs text-[var(--text-muted)] mb-1">API 地址</label>
            <input 
              v-model="syncUrl" 
              type="text" 
              placeholder="http://your-server:3000"
              class="input w-full"
            />
          </div>
          <div>
            <label class="block text-xs text-[var(--text-muted)] mb-1">用户 ID</label>
            <input 
              v-model="userId" 
              type="text" 
              placeholder="唯一标识，手机端需填相同ID"
              class="input w-full"
            />
          </div>
          <div class="flex gap-3 pt-2">
            <button @click="saveConfig" class="btn flex-1">保存配置</button>
            <button 
              @click="syncNow"
              :disabled="syncing || !syncUrl || !userId"
              class="btn-outline flex-1"
            >
              {{ syncing ? '同步中...' : '立即同步' }}
            </button>
          </div>
        </div>
      </div>

      <!-- 自动同步 -->
      <div class="p-6 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
        <div class="text-sm text-[var(--text-secondary)] mb-4">自动同步</div>
        <div class="space-y-4">
          <!-- 定时同步 -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <label class="switch">
                <input type="checkbox" v-model="autoSyncEnabled" @change="saveAutoSyncConfig">
                <span class="slider"></span>
              </label>
              <span class="text-sm text-[var(--text)]">定时同步</span>
            </div>
            <select 
              v-model="autoSyncInterval" 
              :disabled="!autoSyncEnabled"
              @change="saveAutoSyncConfig"
              class="input w-24 text-center disabled:opacity-50"
            >
              <option :value="60">1 分钟</option>
              <option :value="300">5 分钟</option>
              <option :value="600">10 分钟</option>
              <option :value="1800">30 分钟</option>
              <option :value="3600">1 小时</option>
            </select>
          </div>

          <!-- 暂停时同步 -->
          <div class="flex items-center gap-3">
            <label class="switch">
              <input type="checkbox" v-model="syncOnPause" @change="saveAutoSyncConfig">
              <span class="slider"></span>
            </label>
            <span class="text-sm text-[var(--text)]">暂停学习时同步</span>
          </div>

          <!-- 系统通知 -->
          <div class="flex items-center gap-3 pt-2 border-t border-[var(--border)]">
            <label class="switch">
              <input type="checkbox" v-model="notificationsEnabled" @change="saveNotificationsConfig">
              <span class="slider"></span>
            </label>
            <span class="text-sm text-[var(--text)]">系统通知</span>
          </div>

          <!-- 开机启动 -->
          <div class="flex items-center gap-3">
            <label class="switch">
              <input type="checkbox" v-model="autoLaunchEnabled" @change="saveAutoLaunchConfig">
              <span class="slider"></span>
            </label>
            <span class="text-sm text-[var(--text)]">开机启动</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 消息提示 -->
    <div v-if="message" class="mt-6 p-4 rounded border" :class="messageType === 'success' ? 'bg-[var(--bg-secondary)] border-[var(--border)] text-[var(--text)]' : 'bg-red-900/20 border-red-900/30 text-red-400'">
      {{ message }}
    </div>

    <!-- 使用说明 -->
    <div class="mt-6 p-6 bg-[var(--bg-secondary)] rounded border border-[var(--border)]">
      <div class="text-sm text-[var(--text-secondary)] mb-3">使用说明</div>
      <ol class="text-xs text-[var(--text-muted)] space-y-1 list-decimal list-inside">
        <li>部署 cloud-api 到你的服务器</li>
        <li>填入 API 地址和自定义用户 ID</li>
        <li>点击"立即同步"上传数据</li>
        <li>在手机 APP 中填入相同的配置</li>
      </ol>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { invoke } from '@tauri-apps/api/tauri'
import { fetch as tauriFetch, Body, ResponseType } from '@tauri-apps/api/http'

const syncUrl = ref('')
const userId = ref('')
const syncing = ref(false)
const message = ref('')
const messageType = ref<'success' | 'error'>('success')

// 自动同步配置
const autoSyncEnabled = ref(false)
const autoSyncInterval = ref(300)
const syncOnPause = ref(false)
const notificationsEnabled = ref(true)
const autoLaunchEnabled = ref(false)

onMounted(async () => {
  const [url, id] = await invoke<[string | null, string | null]>('get_sync_config')
  syncUrl.value = url || ''
  userId.value = id || ''
  
  const [enabled, interval, onPause] = await invoke<[boolean, number, boolean]>('get_auto_sync_config')
  autoSyncEnabled.value = enabled
  autoSyncInterval.value = interval
  syncOnPause.value = onPause
  
  notificationsEnabled.value = await invoke<boolean>('get_notifications_enabled')
  autoLaunchEnabled.value = await invoke<boolean>('get_auto_launch')
})

const saveConfig = async () => {
  await invoke('set_sync_config', { syncUrl: syncUrl.value, userId: userId.value })
  message.value = '配置已保存'
  messageType.value = 'success'
  setTimeout(() => message.value = '', 2000)
}

const saveAutoSyncConfig = async () => {
  await invoke('set_auto_sync_config', { 
    autoSyncEnabled: autoSyncEnabled.value, 
    autoSyncInterval: autoSyncInterval.value,
    syncOnPause: syncOnPause.value
  })
  // 通知 App.vue 重新初始化同步
  window.dispatchEvent(new CustomEvent('reinit-auto-sync'))
  message.value = '自动同步配置已保存'
  messageType.value = 'success'
  setTimeout(() => message.value = '', 2000)
}

const saveNotificationsConfig = async () => {
  await invoke('set_notifications_enabled', { enabled: notificationsEnabled.value })
}

const saveAutoLaunchConfig = async () => {
  try {
    await invoke('set_auto_launch', { enabled: autoLaunchEnabled.value })
  } catch (e) {
    console.error('设置开机启动失败:', e)
    // 恢复状态
    autoLaunchEnabled.value = !autoLaunchEnabled.value
  }
}

const syncNow = async () => {
  if (!syncUrl.value || !userId.value || syncing.value) return
  
  syncing.value = true
  
  try {
    const data = await invoke<any>('get_sync_data')
    const response = await tauriFetch(`${syncUrl.value}/api/sync`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: Body.json({ userId: userId.value, ...data }),
      responseType: ResponseType.JSON
    })
    
    if (response.ok) {
      const result = response.data as any
      message.value = `同步成功！${result.synced}`
      messageType.value = 'success'
    } else {
      throw new Error(`HTTP ${response.status}`)
    }
  } catch (e: any) {
    message.value = `同步失败: ${JSON.stringify(e)}`
    messageType.value = 'error'
  } finally {
    syncing.value = false
    setTimeout(() => message.value = '', 3000)
  }
}
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
.btn-outline {
  @apply px-4 py-2 border border-[var(--border)] text-[var(--text)] text-sm font-medium rounded transition-colors flex items-center justify-center leading-none;
}
.btn-outline:hover {
  background: var(--bg-tertiary);
}
.btn-outline:disabled {
  @apply opacity-50 cursor-not-allowed;
}

/* 开关样式 */
.switch {
  position: relative;
  display: inline-block;
  width: 36px;
  height: 20px;
}
.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}
.slider {
  position: absolute;
  cursor: pointer;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: var(--border);
  transition: 0.2s;
  border-radius: 20px;
}
.slider:before {
  position: absolute;
  content: "";
  height: 16px;
  width: 16px;
  left: 2px;
  bottom: 2px;
  background-color: white;
  transition: 0.2s;
  border-radius: 50%;
}
input:checked + .slider {
  background-color: var(--text);
}
input:checked + .slider:before {
  transform: translateX(16px);
}
</style>
