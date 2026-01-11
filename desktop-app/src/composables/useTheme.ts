import { ref, watch } from 'vue'

const isDark = ref(localStorage.getItem('theme') !== 'light')

watch(isDark, (dark) => {
  localStorage.setItem('theme', dark ? 'dark' : 'light')
  document.documentElement.classList.toggle('light', !dark)
}, { immediate: true })

export function useTheme() {
  const toggle = () => {
    isDark.value = !isDark.value
  }

  return { isDark, toggle }
}
