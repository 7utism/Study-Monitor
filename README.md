<p align="center">
  <img src="desktop-app/src-tauri/icons/128x128.png" alt="Study Monitor Logo" width="100">
</p>

<h1 align="center">📚 Study Monitor / 快学点儿吧</h1>

<p align="center">
  <strong>Your personal study companion that tracks learning time automatically</strong><br>
  <strong>自动追踪学习时间的个人学习伴侣</strong>
</p>

<p align="center">
  <a href="README_EN.md">English</a> •
  <a href="README_CN.md">中文文档</a>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-how-it-works">How It Works</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-中文说明">中文说明</a> •
  <a href="#-contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android-blue" alt="Platform">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen" alt="PRs Welcome">
</p>

---

## 🌟 Why Study Monitor?

We've all been there — you sit down to study, open your browser, and before you know it, hours have passed. But how much of that time was actually spent learning?

**Study Monitor** was born from a simple idea: *What if your computer could automatically track your study time, just like a fitness tracker counts your steps?*

No more manual timers. No more guessing. Just open your course website and let Study Monitor do the rest.

## ✨ Features

- 🖥️ **Desktop App** — Lightweight Tauri-based app that runs quietly in your system tray
- 🌐 **Browser Extension** — Chrome extension that automatically detects when you're studying
- 📱 **Mobile App** — Check your stats on the go with our Flutter-powered Android app
- ☁️ **Cloud Sync** — Seamlessly sync your data across all your devices
- 📊 **Beautiful Statistics** — Visualize your learning journey with intuitive charts
- 🎯 **Goal Setting** — Set daily goals and track your progress toward exams
- 🔔 **Smart Notifications** — Get notified about your study milestones (optional)
- 🚀 **Auto-start** — Launch automatically with your system

## 🔧 How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Chrome Browser │────▶│   Desktop App   │────▶│   Mobile App    │
│   (Extension)   │     │  (Time Tracker) │     │  (View Stats)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                       │                       │
        │    Detects course     │   Stores locally      │
        │    URL patterns       │   + Cloud sync        │
        └───────────────────────┴───────────────────────┘
```

1. **Add your courses** in the desktop app with URL patterns (e.g., `*coursera.org*`)
2. **Install the Chrome extension** — it talks to your desktop app
3. **Just browse normally** — when you visit a matching URL, timing starts automatically
4. **Check your progress** anywhere — desktop, mobile, or both!

## 🚀 Quick Start

### Desktop App

```bash
cd desktop-app
npm install
npm run tauri dev      # Development
npm run tauri build    # Build for production
```

### Chrome Extension

1. Open Chrome and navigate to `chrome://extensions/`
2. Enable **Developer mode** (top right)
3. Click **Load unpacked**
4. Select the `chrome-extension` folder

### Mobile App (Android)

```bash
cd mobile-app
flutter pub get
flutter run                                              # Development
flutter build apk --release --target-platform android-arm64  # Build APK
```

### Cloud Sync Server (Optional)

```bash
cd cloud-api
npm install
node server.js    # Runs on port 3000 by default
```

## 📁 Project Structure

```
study-monitor/
├── 🖥️ desktop-app/        # Tauri + Vue 3 + TypeScript
│   └── src-tauri/         # Rust backend with SQLite
├── 🌐 chrome-extension/   # Manifest V3 Chrome Extension
├── 📱 mobile-app/         # Flutter (Android)
└── ☁️ cloud-api/          # Node.js + Express + sql.js
```

## 🛠️ Tech Stack

| Component | Technologies |
|-----------|-------------|
| Desktop | Tauri, Vue 3, TypeScript, Rust, SQLite |
| Browser | Chrome Extension (Manifest V3) |
| Mobile | Flutter, Dart |
| Cloud | Node.js, Express, sql.js |

---


## 🇨🇳 中文说明

### 为什么做这个？

备考的日子里，我总是很难准确知道自己每天到底学了多少时间。

手动计时太麻烦，番茄钟又总是忘记开。于是我想：**能不能让电脑自动帮我记录学习时间？**

就像运动手环自动记录步数一样，打开网课页面就自动开始计时，关掉就停止。不需要任何操作，专注学习就好。

**快学点儿吧** 就这样诞生了。

### 功能亮点

- 🖥️ **桌面程序** — 基于 Tauri 的轻量应用，安静地待在系统托盘
- 🌐 **浏览器扩展** — Chrome 扩展自动检测学习页面
- 📱 **手机 APP** — Flutter 开发的 Android 应用，随时查看学习数据
- ☁️ **云同步** — 多设备数据无缝同步
- 📊 **数据统计** — 直观的图表展示学习轨迹
- 🎯 **目标管理** — 设定每日目标，倒计时考试日期
- 🔔 **智能通知** — 学习里程碑提醒（可关闭）
- 🚀 **开机启动** — 随系统自动运行

### 使用方法

#### 第一步：安装桌面程序

```bash
cd desktop-app
npm install
npm run tauri build
```

构建完成后，在 `src-tauri/target/release/bundle` 找到安装包。

#### 第二步：安装浏览器扩展

1. 打开 Chrome，访问 `chrome://extensions/`
2. 开启右上角的「开发者模式」
3. 点击「加载已解压的扩展程序」
4. 选择 `chrome-extension` 文件夹

#### 第三步：添加课程

1. 打开桌面程序
2. 进入「课程」页面
3. 添加课程，设置 URL 匹配规则
   - 例如：`*bilibili.com/video*` 匹配 B 站视频
   - 例如：`*coursera.org*` 匹配 Coursera 所有页面
4. 支持 `*` 通配符

#### 第四步：开始学习

打开匹配的网页，计时自动开始。就这么简单！

### 手机 APP（可选）

```bash
cd mobile-app
flutter pub get
flutter build apk --release --target-platform android-arm64
```

APK 文件在 `build/app/outputs/flutter-apk/` 目录。

### 云同步服务（可选）

如果你想在多台设备间同步数据：

```bash
cd cloud-api
npm install
node server.js
```

然后在桌面程序和手机 APP 的设置中配置服务器地址。

---

## 🤝 Contributing

Contributions are welcome! Whether it's:

- 🐛 Bug reports
- 💡 Feature suggestions  
- 🔧 Pull requests
- 📖 Documentation improvements
- 🌍 Translations

Feel free to open an issue or submit a PR.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 💬 Feedback

If Study Monitor helps you stay focused, I'd love to hear about it! 

有任何问题或建议，欢迎提 Issue 交流 ✨

---

<p align="center">
  Made with ❤️ for learners everywhere<br>
  <sub>献给每一个努力学习的你</sub>
</p>
