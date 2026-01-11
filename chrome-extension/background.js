const API_BASE = 'http://127.0.0.1:23333';

let courses = [];
let currentCourseId = null;
let isStudying = false;
let lastReportTime = 0;

// 初始化
chrome.runtime.onInstalled.addListener(() => {
  console.log('学习监督助手已安装');
  fetchCourses();
});

// 启动时获取课程
chrome.runtime.onStartup.addListener(() => {
  fetchCourses();
});

// 设置定时器
chrome.alarms.create('checkStatus', { periodInMinutes: 0.1 });

chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === 'checkStatus') {
    checkCurrentTab();
  }
});

// 监听标签页变化
chrome.tabs.onActivated.addListener(() => {
  checkCurrentTab();
});

chrome.tabs.onUpdated.addListener((_, changeInfo, tab) => {
  if (changeInfo.status === 'complete' && tab.active) {
    checkCurrentTab();
  }
});

// 获取课程配置
async function fetchCourses() {
  try {
    const response = await fetch(`${API_BASE}/courses`);
    const result = await response.json();
    if (result.success && result.data) {
      courses = result.data;
      console.log('课程配置已更新:', courses.length, '个课程');
      chrome.storage.local.set({ courses });
    }
  } catch (error) {
    console.error('获取课程配置失败:', error);
    chrome.storage.local.get(['courses'], (result) => {
      if (result.courses) {
        courses = result.courses;
      }
    });
  }
}

// 检查当前标签页
async function checkCurrentTab() {
  try {
    const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
    if (!tab || !tab.url) {
      handleNoMatch();
      return;
    }

    const matchedCourse = matchCourse(tab.url);
    
    if (matchedCourse) {
      handleMatch(matchedCourse, tab.url);
    } else {
      handleNoMatch();
    }
  } catch (error) {
    console.error('检查标签页失败:', error);
  }
}

// URL 匹配课程
function matchCourse(url) {
  for (const course of courses) {
    if (matchPattern(url, course.url_pattern)) {
      return course;
    }
  }
  return null;
}

// 通配符匹配
function matchPattern(url, pattern) {
  // 转义正则特殊字符，* 转换为 .*
  let regexPattern = '';
  for (const char of pattern) {
    if (char === '*') {
      regexPattern += '.*';
    } else if ('.+?^${}()|[]\\'.includes(char)) {
      regexPattern += '\\' + char;
    } else {
      regexPattern += char;
    }
  }
  
  const regex = new RegExp(regexPattern, 'i');
  return regex.test(url);
}

// 匹配到课程
async function handleMatch(course, url) {
  const now = Math.floor(Date.now() / 1000);
  
  if (currentCourseId !== course.id || !isStudying) {
    currentCourseId = course.id;
    isStudying = true;
    await reportStatus(course.id, true, url);
    lastReportTime = now;
  } else if (now - lastReportTime >= 5) {
    await reportStatus(course.id, true, url);
    lastReportTime = now;
  }

  updateBadge(true, course.name);
}

// 未匹配到课程
async function handleNoMatch() {
  if (isStudying && currentCourseId) {
    await reportStatus(currentCourseId, false, '');
  }
  
  currentCourseId = null;
  isStudying = false;
  updateBadge(false);
}

// 上报状态
async function reportStatus(courseId, active, url) {
  try {
    const response = await fetch(`${API_BASE}/status`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        course_id: courseId,
        active,
        timestamp: Math.floor(Date.now() / 1000),
        url
      })
    });
    
    const result = await response.json();
    console.log('状态上报:', active ? '学习中' : '已停止', result);
  } catch (error) {
    console.error('状态上报失败:', error);
  }
}

// 更新图标徽章
function updateBadge(studying, courseName = '') {
  if (studying) {
    chrome.action.setBadgeText({ text: '学' });
    chrome.action.setBadgeBackgroundColor({ color: '#4ade80' });
    chrome.action.setTitle({ title: `正在学习: ${courseName}` });
  } else {
    chrome.action.setBadgeText({ text: '' });
    chrome.action.setTitle({ title: '学习监督助手' });
  }
}

// 监听来自 popup 的消息
chrome.runtime.onMessage.addListener((message, _, sendResponse) => {
  if (message.type === 'getStatus') {
    sendResponse({
      isStudying,
      currentCourseId,
      courses
    });
  } else if (message.type === 'refreshCourses') {
    fetchCourses().then(() => {
      sendResponse({ success: true, courses });
    });
    return true;
  }
});

// 初始获取课程
fetchCourses();
