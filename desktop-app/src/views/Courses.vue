<template>
  <div>
    <h1 class="text-lg font-medium mb-6 text-[var(--text)]">课程管理</h1>
    
    <form @submit.prevent="saveCourse" class="grid grid-cols-4 gap-3 mb-6">
      <input v-model="form.name" placeholder="课程名称" class="input" required />
      <input v-model="form.subject" placeholder="科目" class="input" required />
      <input v-model="form.urlPattern" placeholder="URL规则 (*通配符)" class="input" required />
      <div class="flex gap-2">
        <button type="submit" class="btn flex-1">{{ editingCourse ? '保存' : '添加' }}</button>
        <button v-if="editingCourse" type="button" @click="cancelEdit" class="btn-secondary">取消</button>
      </div>
    </form>

    <div class="space-y-2">
      <div
        v-for="course in courses"
        :key="course.id"
        class="flex items-center justify-between p-3 bg-[var(--bg-secondary)] rounded border border-[var(--border)] group"
      >
        <div>
          <span class="text-[var(--text)]">{{ course.name }}</span>
          <span class="text-[var(--text-muted)] mx-2">·</span>
          <span class="text-[var(--text-secondary)]">{{ course.subject }}</span>
          <code class="ml-3 text-xs text-[var(--text-muted)] bg-[var(--bg)] px-2 py-0.5 rounded">{{ course.url_pattern }}</code>
        </div>
        <div class="opacity-0 group-hover:opacity-100 transition-opacity flex gap-1">
          <button @click="editCourse(course)" class="px-2 py-1 text-xs text-[var(--text-secondary)] hover:text-[var(--text)]">编辑</button>
          <button @click="deleteCourse(course.id)" class="px-2 py-1 text-xs text-[var(--text-secondary)] hover:text-red-400">删除</button>
        </div>
      </div>
      <div v-if="!courses.length" class="text-center py-12 text-[var(--text-muted)]">暂无课程</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted } from 'vue'
import { invoke } from '@tauri-apps/api/tauri'

interface Course { id: string; name: string; subject: string; url_pattern: string }

const courses = ref<Course[]>([])
const editingCourse = ref<Course | null>(null)
const form = ref({ name: '', subject: '', urlPattern: '' })

const loadCourses = async () => { 
  try {
    courses.value = await invoke('get_courses') 
  } catch (e) {
    console.error('加载课程失败:', e)
  }
}

const saveCourse = async () => {
  if (editingCourse.value) {
    await invoke('update_course', { 
      id: editingCourse.value.id, 
      name: form.value.name,
      subject: form.value.subject,
      urlPattern: form.value.urlPattern
    })
  } else {
    await invoke('add_course', {
      name: form.value.name,
      subject: form.value.subject,
      urlPattern: form.value.urlPattern
    })
  }
  resetForm()
  await loadCourses()
}

const editCourse = (c: Course) => {
  editingCourse.value = c
  form.value = { name: c.name, subject: c.subject, urlPattern: c.url_pattern }
}

const cancelEdit = () => resetForm()

const resetForm = () => {
  editingCourse.value = null
  form.value = { name: '', subject: '', urlPattern: '' }
}

const deleteCourse = async (id: string) => {
  if (confirm('确定删除？')) {
    await invoke('delete_course', { id })
    await loadCourses()
  }
}

let timer: number
onMounted(() => {
  loadCourses()
  timer = window.setInterval(loadCourses, 3000)
})
onUnmounted(() => clearInterval(timer))
</script>

<style scoped>
.input {
  @apply px-3 py-2 bg-[var(--bg)] border border-[var(--border)] rounded text-[var(--text)] text-sm placeholder-[var(--text-muted)] outline-none transition-colors;
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
.btn-secondary {
  @apply px-4 py-2 bg-[var(--border)] text-[var(--text)] text-sm rounded transition-colors flex items-center justify-center leading-none;
}
.btn-secondary:hover {
  background: var(--bg-tertiary);
}
</style>
