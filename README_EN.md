<p align="center">
  <img src="desktop-app/src-tauri/icons/128x128.png" alt="Study Monitor Logo" width="100">
</p>

<h1 align="center">📚 Study Monitor</h1>

<p align="center">
  <strong>Your personal study companion that tracks learning time automatically</strong>
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-how-it-works">How It Works</a> •
  <a href="#-installation">Installation</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Android-blue" alt="Platform">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen" alt="PRs Welcome">
</p>

---

## 🌟 The Story Behind This

We've all been there — you sit down to study, open your browser, and before you know it, hours have passed. But how much of that time was actually spent learning?

During my exam preparation, I struggled to track my actual study time. Manual timers were tedious, and I always forgot to start the Pomodoro clock.

Then I thought: **What if my computer could automatically track my study time, just like a fitness tracker counts steps?**

Open a course website → timer starts. Close it → timer stops. No buttons to press, no apps to remember. Just focus on learning.

That's how **Study Monitor** was born.

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🖥️ **Desktop App** | Lightweight Tauri-based app that runs quietly in your system tray |
| 🌐 **Browser Extension** | Chrome extension that automatically detects when you're on a learning page |
| 📱 **Mobile App** | Check your stats on the go with our Flutter-powered Android app |
| ☁️ **Cloud Sync** | Seamlessly sync your data across all your devices |
| 📊 **Beautiful Statistics** | Visualize your learning journey with intuitive charts |
| 🎯 **Goal Setting** | Set daily goals and countdown to your exam date |
| 🔔 **Smart Notifications** | Get notified about your study milestones (can be disabled) |
| 🚀 **Auto-start** | Launch automatically with your system |

## 🔧 How It Works

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Chrome Browser │────▶│   Desktop App   │────▶│   Mobile App    │
│   (Extension)   │     │  (Time Tracker) │     │  (View Stats)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

1. **The Chrome extension** monitors your browser tabs
2. **When you visit a URL** that matches one of your courses, it notifies the desktop app
3. **The desktop app** starts timing and stores everything in a local SQLite database
4. **Optionally sync** to the cloud and view your stats on your phone

### URL Pattern Matching

Study Monitor uses simple wildcard patterns to match URLs:

- `*coursera.org*` — matches any Coursera page
- `*youtube.com/watch*` — matches YouTube videos
- `*udemy.com/course/*` — matches Udemy course pages

## 🚀 Installation

### Prerequisites

- **Node.js** 18+ (for desktop app and cloud API)
- **Rust** (for Tauri desktop app)
- **Flutter** 3.0+ (for mobile app)
- **Chrome** browser (for the extension)

### Desktop App

```bash
cd desktop-app
npm install

# Development
npm run tauri dev

# Build for production
npm run tauri build
```

The installer will be in `src-tauri/target/release/bundle/`.

### Chrome Extension

1. Open Chrome and go to `chrome://extensions/`
2. Enable **Developer mode** (toggle in top right)
3. Click **Load unpacked**
4. Select the `chrome-extension` folder
5. Pin the extension for easy access

### Mobile App (Android)

```bash
cd mobile-app
flutter pub get

# Development
flutter run

# Build release APK (64-bit only)
flutter build apk --release --target-platform android-arm64
```

Find the APK in `build/app/outputs/flutter-apk/`.

### Cloud Sync Server (Optional)

If you want to sync data across devices:

```bash
cd cloud-api
npm install
node server.js
```

The server runs on port 3000 by default. Configure the server URL in both the desktop app and mobile app settings.

## 📖 Usage

### Step 1: Add Your Courses

1. Open the desktop app
2. Go to the **Courses** tab
3. Click **Add Course**
4. Enter the course name and URL pattern
5. Save

### Step 2: Start Learning

That's it! Just open a webpage that matches your course URL pattern, and timing starts automatically.

- ✅ Timer starts when you're on a matching page
- ⏸️ Timer pauses when you switch to a non-matching tab
- ⏹️ Timer stops when you close the browser or the matching tab

### Step 3: Check Your Progress

- **Desktop**: View daily/weekly/monthly statistics with beautiful charts
- **Mobile**: Sync your data and check progress anywhere
- **Goals**: Set daily study goals and exam countdown

## 📁 Project Structure

```
study-monitor/
├── 🖥️ desktop-app/          # Tauri + Vue 3 + TypeScript
│   ├── src/                 # Vue frontend
│   └── src-tauri/           # Rust backend
│       └── src/
│           ├── main.rs      # App entry & system tray
│           ├── db.rs        # SQLite database
│           └── http_server.rs # Local API for extension
│
├── 🌐 chrome-extension/     # Manifest V3
│   ├── manifest.json
│   ├── background.js        # Service worker
│   ├── popup.html/js        # Extension popup
│   └── icons/
│
├── 📱 mobile-app/           # Flutter
│   └── lib/
│       ├── main.dart
│       ├── screens/         # UI screens
│       └── services/        # API services
│
└── ☁️ cloud-api/            # Node.js + Express
    └── server.js            # REST API with sql.js
```

## 🛠️ Tech Stack

| Component | Technologies |
|-----------|-------------|
| **Desktop** | Tauri 1.x, Vue 3, TypeScript, Rust, SQLite, Tailwind CSS |
| **Browser** | Chrome Extension Manifest V3, Vanilla JS |
| **Mobile** | Flutter 3.x, Dart, fl_chart |
| **Cloud** | Node.js, Express, sql.js, CORS |

## 🔒 Privacy

Study Monitor is designed with privacy in mind:

- **Local-first**: All data is stored locally by default
- **No tracking**: We don't collect any analytics or telemetry
- **Optional sync**: Cloud sync is completely optional
- **Self-hosted**: You can run your own sync server
- **Open source**: Audit the code yourself

## 🤝 Contributing

Contributions are warmly welcomed! Here's how you can help:

- 🐛 **Report bugs** — Found something broken? Open an issue!
- 💡 **Suggest features** — Have an idea? Let's discuss it!
- 🔧 **Submit PRs** — Code contributions are always appreciated
- 📖 **Improve docs** — Help make the documentation better
- 🌍 **Translate** — Help translate to other languages

### Development Setup

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Tauri](https://tauri.app/) — For making cross-platform desktop apps a breeze
- [Vue.js](https://vuejs.org/) — For the delightful frontend framework
- [Flutter](https://flutter.dev/) — For beautiful cross-platform mobile development
- [fl_chart](https://pub.dev/packages/fl_chart) — For the gorgeous charts

## 💬 Feedback

If Study Monitor helps you stay focused and achieve your learning goals, I'd love to hear about it!

Feel free to:
- ⭐ Star this repo if you find it useful
- 🐦 Share your experience
- 📧 Open an issue for questions or suggestions

---

<p align="center">
  Made with ❤️ for learners everywhere
</p>
