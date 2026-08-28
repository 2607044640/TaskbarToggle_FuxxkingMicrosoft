# Windows Taskbar Auto-Hide Fix & Smart Toggle (AutoHotkey v2)

<p align="center">
  <b>English</b> | <a href="#-中文说明">简体中文</a>
</p>

<p align="center">
  <a href="https://www.autohotkey.com/"><img src="https://img.shields.io/badge/Language-AutoHotkey%20v2.0+-green.svg" alt="AutoHotkey v2"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License"></a>
  <a href="https://microsoft.com"><img src="https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-0078D6.svg" alt="Platform"></a>
</p>

> Eliminate Windows auto-hide taskbar bugs, suppress rogue third-party notification popups, and enjoy a seamless immersive experience with **Triple-Win Temporary Lock**, **Instant `Win+Num` App Switching**, and **Outside-Click Auto-Dismissal**.

---

## 📌 Why This Tool? (The Problem)

Windows built-in **"Automatically hide the taskbar"** is essential for immersive work, gaming, coding, and media consumption. However, Windows taskbar management suffers from critical architectural bugs:

1. **Rogue Notification Popups (Stuck on Screen)**:
   - Messaging apps (WeChat, QQ, Discord, DingTalk, Telegram) frequently call `NIM_MODIFY` to update tray icons or notifications. This bypasses user auto-hide preferences, forcing `Shell_TrayWnd` to pop up and remain permanently stuck on screen.
2. **State De-synchronization**:
   - The taskbar frequently refuses to retract after being triggered, requiring multiple spam clicks or random keypresses to hide again.
3. **The Frustration of Organizing Pinned Icons**:
   - When you need to reorder pinned taskbar icons, click tray flyouts, or use taskbar search, moving your mouse a fraction of a millimeter off the taskbar immediately collapses it, making icon management frustratingly difficult.

This lightweight AutoHotkey v2 script uses low-level Windows API (`User32\ShowWindow`) control, an intelligent watchdog inspector, and a robust state machine to completely solve these issues.

---

## 🌟 Recommended: Use Version 8 (V8)

This repository includes the entire evolutionary history (V5 to V8). **For daily use, strongly recommended to run `8TaskbarToggle_FuxxkingMicrosoft.ahk`**.

### 💡 Feature Comparison

| Feature | V8 (Recommended ⭐⭐⭐⭐⭐) | V7 (Legacy) |
| :--- | :--- | :--- |
| **Persistent Lock Trigger** | **Rapid Triple-Win Tap** (450ms window, zero accidental triggers) | Single Win press (too easy to trigger accidentally) |
| **Dismiss Persistent Mode** | **Click anywhere outside taskbar UI** OR **Single-tap Win** | Depends on Start Menu close detection (prone to getting stuck) |
| **Fast `Win+1/2/3/4...` App Switching** | **Flawless & Instant** (Taskbar appears on keydown for Explorer targeting, auto-hides 150ms after release) | Only works when taskbar is already open or start menu is up |
| **Windows Shortcut Keys** | Full native support (`Win+E`, `Win+R`, `Win+D`, `Win+V`, `Win+Tab`) | Supported |
| **Rogue Notification Suppression** | **800ms Watchdog Inspector** (Suppresses popup glitches within <1s) | 800ms Watchdog Inspector |
| **Reorder Pinned Icons** | Lock taskbar via 3x Win tap, **drag and reorder icons with ease** | Easily collapses during drag |

---

## ⚙️ Prerequisites (Windows Settings)

For this script to function as intended, **you MUST enable "Automatically hide the taskbar in desktop mode" in Windows Settings**.

### Setup Steps:
1. Open Windows **Settings** -> **Personalization** -> **Taskbar**.
2. Toggle **"Automatically hide the taskbar in desktop mode"** to **On**.

![Windows Taskbar Settings](taskbar_settings.png)

> **Recommended Configuration**:
> - **Lock the taskbar**: Off
> - **Automatically hide the taskbar in desktop mode**: **On** (Required)
> - **Automatically hide the taskbar in tablet mode**: Off
> - **Use small taskbar buttons**: On (Optional, based on preference)
> - **Taskbar location on screen**: Bottom

---

## 🕹️ V8 Controls & Interactions

### 1. Default Mode (Always Hidden)
- The taskbar remains completely hidden for an uninterrupted full-screen experience.
- The **Watchdog Inspector** checks every 800ms. If a background app forces the taskbar open via notification hooks, it is forcibly hidden (`SW_HIDE`) within 1 second.
- Pressing `Win+1`, `Win+2`, `Win+3` immediately switches pinned apps; the taskbar auto-retracts 150ms after releasing the keys.
- Standard shortcuts (`Win+E`, `Win+R`, `Win+V`, etc.) execute normally without leaving the taskbar stranded.

### 2. Temporary Persistent Mode (Organize Icons / Search)
- **Quickly tap the Win key 3 times** (within 450ms).
- The taskbar appears smoothly and enters **Temporary Persistent Mode**:
  - The watchdog inspector sleeps; the taskbar remains permanently visible.
  - You can freely drag and reorder pinned icons, click search, access system tray icons, and right-click context menus.

### 3. Exit Persistent Mode (Dual Dismissal)
- **Method A (Click Outside)**: Click anywhere outside the taskbar UI, Start Menu, or tray flyouts (e.g., desktop, browser, IDE). The taskbar hides immediately.
- **Method B (Press Win)**: Single-tap the Win key to immediately dismiss the taskbar.

---

## 🚀 Installation & Setup

### Requirements
- Windows 10 / Windows 11 (64-bit)
- **[AutoHotkey v2.0+](https://www.autohotkey.com/)** (Required: v2 syntax, not compatible with v1)

### Quick Run
1. Install AutoHotkey v2.
2. Double-click `8TaskbarToggle_FuxxkingMicrosoft.ahk`. (The script automatically requests Admin rights to ensure it can manage windows over elevated applications).

### Auto-start with Windows
1. Press `Win + R`, type `shell:startup`, and press Enter to open the Startup folder.
2. Create a **shortcut** for `8TaskbarToggle_FuxxkingMicrosoft.ahk`.
3. Paste the shortcut into the Startup folder.

---

## 📂 Repository File Structure

- **`8TaskbarToggle_FuxxkingMicrosoft.ahk`**: 🌟 **Recommended**. V8 state-machine architecture with triple-Win lock, outside-click dismissal, instant `Win+Num` switching, and watchdog inspector.
- **`7TaskbarToggle_FuxxkingMicrosoft.ahk`**: V7 legacy version (single-Win toggle).
- **`6TaskbarToggle_FuxxkingMicrosoft.ahk`**: V6 prototype version.
- **`5TaskbarToggle_FuxxkingMicrosoft.ahk`**: V5 base prototype.
- **`taskbar_settings.png`**: Prerequisite Windows taskbar settings screenshot.

---
---

## 🇨🇳 中文说明

<p align="center">
  <a href="#windows-taskbar-auto-hide-fix--smart-toggle-autohotkey-v2">返回顶部 (English)</a>
</p>

### 📌 痛点与背景

Windows 自带的「自动隐藏任务栏」在全屏办公、编程、打游戏或观看视频时能提供极致的沉浸空间，但底层存在严重的恶性 Bug：

1. **微信/QQ/钉钉等通知偷弹卡死**：应用通过 `NIM_MODIFY` 刷新托盘通知时，会强行顶起 Windows 任务栏（`Shell_TrayWnd`）并卡在最前端，遮挡画面且无法自动缩回。
2. **状态不同步与失效**：按 Win 键有时藏不回去，经常需要连按好几次或狂点屏幕。
3. **临时整理图标极度痛苦**：想拖拽整理 Pin 图标或使用任务栏搜索时，鼠标稍有偏移任务栏立刻收缩，无法稳定操作。

本项目通过精准的 Windows API（`User32\ShowWindow`）控制 + 800ms 看门狗巡查 + 智能按键状态机，彻底解决上述所有痛点。

---

### 🌟 强烈推荐使用 V8 版本

日常使用强烈推荐直接运行 **`8TaskbarToggle_FuxxkingMicrosoft.ahk`**！

#### V8 核心特性：
1. **快速连按 3 下 Win 键（暂时持久化）**：
   - 450ms 窗口内连续轻按 3 次 Win 键，呼出并**锁定任务栏常驻显示**。
   - 常驻状态下看门狗自动休眠，用户可从容**拖拽排序 Pin 图标**、使用任务栏搜索与托盘。
2. **双重退出机制**：
   - **点外部退出**：点击任务栏 UI 区域以外的任何屏幕位置（桌面、浏览器、IDE等），任务栏秒收回。
   - **按 Win 退出**：在持久化模式下单按 1 次 Win 键，任务栏秒收回。
3. **秒级 `Win+1/2/3/4...` Pin 软件切换**：
   - 按下 Win 瞬间毫秒级显示任务栏供系统定位，松开 150ms 自动隐藏，零延迟零残留。
4. **800ms 看门狗 (Inspector)**：
   - 常态隐藏模式下后台每 800ms 巡查一次，微信/QQ 偷弹的任务栏在 1 秒内必被强行压回。
5. **组合键零冲突**：
   - `Win+E`、`Win+R`、`Win+D`、`Win+V`、`Win+Tab` 原生系统组合键正常生效，不误触发三击计数。

---

### ⚙️ 必备前提设置

使用前必须在 Windows 设置中开启 **「在桌面模式下自动隐藏任务栏」**（参考项目中的 `taskbar_settings.png` 截图）。

- 设置路径：`Windows 设置` -> `个性化` -> `任务栏` -> 开启「在桌面模式下自动隐藏任务栏」。

---

### 🚀 安装与开机自启

1. 安装 **[AutoHotkey v2.0+](https://www.autohotkey.com/)**。
2. 双击运行 `8TaskbarToggle_FuxxkingMicrosoft.ahk`（自动申请管理员权限）。
3. 开机自启：按 `Win + R` 输入 `shell:startup`，将脚本的快捷方式放入该文件夹即可。

---

## 📄 License

MIT License © 2026 Jeff.
