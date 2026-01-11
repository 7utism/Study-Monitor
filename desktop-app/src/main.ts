import { createApp } from 'vue'
import { createRouter, createWebHistory } from 'vue-router'
import App from './App.vue'
import Dashboard from './views/Dashboard.vue'
import Courses from './views/Courses.vue'
import Goals from './views/Goals.vue'
import Statistics from './views/Statistics.vue'
import Sync from './views/Sync.vue'
import './style.css'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', redirect: '/dashboard' },
    { path: '/dashboard', component: Dashboard },
    { path: '/courses', component: Courses },
    { path: '/goals', component: Goals },
    { path: '/statistics', component: Statistics },
    { path: '/sync', component: Sync },
  ],
})

createApp(App).use(router).mount('#app')
