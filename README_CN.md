<p align="center">
  <img src="desktop-app/src-tauri/icons/128x128.png" alt="快学点儿吧" width="100">
</p>

<h1 align="center">📚 快学点儿吧</h1>

<p align="center">
  <strong>自动追踪学习时间的个人学习伴侣</strong>
</p>

<p align="center">
  <a href="#-为什么做这个">缘起</a> •
  <a href="#-功能亮点">功能</a> •
  <a href="#-快速开始">安装</a> •
  <a href="#-使用指南">使用</a> •
  <a href="#-参与贡献">贡献</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/平台-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android-blue" alt="Platform">
  <img src="https://img.shields.io/badge/许可证-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/欢迎-PR-brightgreen" alt="PRs Welcome">
</p>

---

## 🌟 为什么做这个？

备考的日子里，我总是很难准确知道自己每天到底学了多少时间。

手动计时太麻烦，番茄钟又总是忘记开。坐在电脑前一整天，感觉学了很久，但实际有效学习时间可能只有几个小时。

于是我想：**能不能让电脑自动帮我记录学习时间？**

就像运动手环自动记录步数一样——打开网课页面就自动开始计时，关掉就停止。不需要任何操作，专注学习就好。

**快学点儿吧** 就这样诞生了。

## ✨ 功能亮点

| 功能 | 说明 |
|------|------|
| 🖥️ **桌面程序** | 基于 Tauri 的轻量应用，安静地待在系统托盘 |
| 🌐 **浏览器扩展** | Chrome 扩展自动检测学习页面，无需手动操作 |
| 📱 **手机 APP** | Flutter 开发的 Android 应用，随时随地查看学习数据 |
| ☁️ **云同步** | 多设备数据无缝同步，电脑手机数据互通 |
| 📊 **数据统计** | 直观的图表展示学习轨迹，日/周/月维度分析 |
| 🎯 **目标管理** | 设定每日目标，倒计时考试日期 |
| 🔔 **智能通知** | 学习里程碑提醒（可关闭，不打扰你） |
| 🚀 **开机启动** | 随系统自动运行，打开电脑就开始守护 |

## 🔧 工作原理

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Chrome 浏览器  │────▶│     桌面程序     │────▶│    手机 APP     │
│    (扩展程序)    │     │   (时间记录器)   │     │   (查看统计)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. **Chrome 扩展** 监控你的浏览器标签页
2. **当你访问的 URL** 匹配某个课程时，通知桌面程序
3. **桌面程序** 开始计时，数据存储在本地 SQLite 数据库
4. **可选同步** 到云端，在手机上查看统计数据

### URL 匹配规则

使用简单的通配符模式匹配 URL：

- `*bilibili.com/video*` — 匹配 B 站视频页面
- `*coursera.org*` — 匹配 Coursera 所有页面
- `*mooc.cn*` — 匹配中国大学 MOOC
- `*youtube.com/watch*` — 匹配 YouTube 视频

## 🚀 快速开始

### 环境要求

- **Node.js** 18+（桌面程序和云服务）
- **Rust**（Tauri 桌面程序）
- **Flutter** 3.0+（手机 APP）
- **Chrome** 浏览器（扩展程序）

### 桌面程序

```bash
cd desktop-app
npm install

# 开发模式
npm run tauri dev

# 构建安装包
npm run tauri build
```

安装包在 `src-tauri/target/release/bundle/` 目录。

### Chrome 扩展

1. 打开 Chrome，访问 `chrome://extensions/`
2. 开启右上角的「开发者模式」
3. 点击「加载已解压的扩展程序」
4. 选择 `chrome-extension` 文件夹
5. 建议固定扩展到工具栏，方便查看状态

### 手机 APP（Android）

```bash
cd mobile-app
flutter pub get

# 开发模式
flutter run

# 构建 APK（仅 64 位）
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

服务默认运行在 3000 端口。在桌面程序和手机 APP 的设置中配置服务器地址即可。

## 📖 使用指南

### 第一步：添加课程

1. 打开桌面程序
2. 进入「课程」页面
3. 点击「添加课程」
4. 输入课程名称和 URL 匹配规则
5. 保存

**URL 规则示例：**
| 平台 | URL 规则 |
|------|----------|
| B 站 | `*bilibili.com/video*` |
| 网易公开课 | `*open.163.com*` |
| Coursera | `*coursera.org*` |
| 中国大学 MOOC | `*icourse163.org*` |

### 第二步：开始学习

就这样！打开匹配的网页，计时自动开始。

- ✅ 访问匹配页面 → 计时开始
- ⏸️ 切换到其他标签页 → 计时暂停
- ⏹️ 关闭浏览器或匹配标签 → 计时停止

### 第三步：查看进度

- **桌面端**：查看日/周/月统计图表
- **手机端**：同步数据后随时查看
- **目标页**：设置每日目标和考试倒计时

## 📁 项目结构

```
study-monitor/
├── 🖥️ desktop-app/          # Tauri + Vue 3 + TypeScript
│   ├── src/                 # Vue 前端
│   └── src-tauri/           # Rust 后端
│       └── src/
│           ├── main.rs      # 应用入口 & 系统托盘
│           ├── db.rs        # SQLite 数据库
│           └── http_server.rs # 本地 API（供扩展调用）
│
├── 🌐 chrome-extension/     # Manifest V3
│   ├── manifest.json
│   ├── background.js        # Service Worker
│   ├── popup.html/js        # 扩展弹窗
│   └── icons/
│
├── 📱 mobile-app/           # Flutter
│   └── lib/
│       ├── main.dart
│       ├── screens/         # 页面
│       └── services/        # API 服务
│
└── ☁️ cloud-api/            # Node.js + Express
    └── server.js            # REST API
```

## 🛠️ 技术栈

| 组件 | 技术 |
|------|------|
| **桌面端** | Tauri 1.x, Vue 3, TypeScript, Rust, SQLite, Tailwind CSS |
| **浏览器扩展** | Chrome Extension Manifest V3, 原生 JS |
| **移动端** | Flutter 3.x, Dart, fl_chart |
| **云服务** | Node.js, Express, sql.js |

## 🔒 隐私说明

**快学点儿吧** 在设计时充分考虑了隐私保护：

- **本地优先**：所有数据默认存储在本地
- **无追踪**：不收集任何分析数据或遥测信息
- **可选同步**：云同步完全可选，不强制
- **自托管**：你可以运行自己的同步服务器
- **开源透明**：代码完全开源，欢迎审查

## 🤝 参与贡献

欢迎各种形式的贡献！

- 🐛 **报告 Bug** — 发现问题？提个 Issue！
- 💡 **功能建议** — 有好点子？一起讨论！
- 🔧 **提交 PR** — 代码贡献永远受欢迎
- 📖 **完善文档** — 帮助改进文档
- 🌍 **翻译** — 帮助翻译成其他语言

### 开发流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m '添加某个很棒的功能'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 提交 Pull Request

## 📝 开源许可

本项目基于 MIT 许可证开源 - 详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Tauri](https://tauri.app/) — 让跨平台桌面开发变得简单
- [Vue.js](https://vuejs.org/) — 优雅的前端框架
- [Flutter](https://flutter.dev/) — 美观的跨平台移动开发
- [fl_chart](https://pub.dev/packages/fl_chart) — 漂亮的图表库

## 💬 反馈

如果 **快学点儿吧** 帮助你保持专注、实现学习目标，我会非常开心！

欢迎：
- ⭐ 给项目点个 Star
- 📧 提 Issue 交流问题或建议
- 🔗 分享给需要的朋友

---

<p align="center">
  Made with ❤️ for learners everywhere<br>
  <sub>献给每一个努力学习的你</sub>
</p>
