const API_BASE = 'http://127.0.0.1:23333';

document.addEventListener('DOMContentLoaded', () => {
  checkConnection();
  loadStatus();
  
  document.getElementById('refreshBtn').addEventListener('click', refreshCourses);
});

async function checkConnection() {
  const statusEl = document.getElementById('connectionStatus');
  
  try {
    const response = await fetch(`${API_BASE}/health`);
    const result = await response.json();
    
    if (result.success) {
      statusEl.textContent = '已连接';
      statusEl.className = 'connection connected';
    } else {
      throw new Error('连接失败');
    }
  } catch (error) {
    statusEl.textContent = '未连接';
    statusEl.className = 'connection disconnected';
  }
}

function loadStatus() {
  chrome.runtime.sendMessage({ type: 'getStatus' }, (response) => {
    if (response) {
      updateStatusUI(response);
      renderCourseList(response.courses);
    }
  });
}

function updateStatusUI(status) {
  const dotEl = document.getElementById('statusDot');
  const textEl = document.getElementById('statusText');
  const courseEl = document.getElementById('courseName');
  
  if (status.isStudying) {
    dotEl.className = 'status-dot active';
    textEl.textContent = '学习中';
    textEl.className = 'status-text active';
    
    const course = status.courses.find(c => c.id === status.currentCourseId);
    if (course) {
      courseEl.textContent = course.name;
      courseEl.style.display = 'block';
    }
  } else {
    dotEl.className = 'status-dot';
    textEl.textContent = '未在学习';
    textEl.className = 'status-text';
    courseEl.style.display = 'none';
  }
}

function renderCourseList(courses) {
  const listEl = document.getElementById('courseList');
  
  if (!courses || courses.length === 0) {
    listEl.innerHTML = '<div class="empty-state">暂无课程配置<br>请在桌面应用中添加</div>';
    return;
  }
  
  listEl.innerHTML = courses.map(course => `
    <div class="course-item">
      <div class="name">${escapeHtml(course.name)}</div>
      <div class="pattern">${escapeHtml(course.url_pattern)}</div>
    </div>
  `).join('');
}

function refreshCourses() {
  const btn = document.getElementById('refreshBtn');
  btn.textContent = '刷新中...';
  btn.disabled = true;
  
  chrome.runtime.sendMessage({ type: 'refreshCourses' }, (response) => {
    btn.textContent = '刷新配置';
    btn.disabled = false;
    
    if (response && response.success) {
      renderCourseList(response.courses);
      checkConnection();
    }
  });
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}
