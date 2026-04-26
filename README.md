# Claude Bar

A lightweight macOS menubar app that monitors your Claude.ai Pro/Max usage in real-time.

![ClaudeBar menubar screenshot](https://github.com/user-attachments/assets/b2310755-5f11-40cf-ba8a-691969234e08)

## Features

- **Menubar indicator** — `Claude ●●` with color-coded dots showing session and weekly usage at a glance
- **Color states** — 🟢 Green (<80%), 🟠 Orange (80–90%), 🔴 Red (≥90%)
- **Click to expand** — Detailed popover with Session, Weekly, and Sonnet usage
- **Reset countdown** — Shows exactly how long until each limit resets
- **Auto-refresh** — Configurable interval (30s / 1m / 5m / 10m / 30m)
- **No API key needed** — Reads OAuth credentials directly from Claude Code's macOS Keychain

## Requirements

- macOS 14 (Sonoma) or later
- [Claude Code](https://claude.ai/code) installed and logged in (`claude /login`)
- Claude Pro, Max, or Team plan

## Installation

### 1. Install Xcode Command Line Tools (if not already installed)

```bash
xcode-select --install
```

### 2. Clone and build

```bash
git clone https://github.com/YOUR_USERNAME/claude-bar.git
cd claude-bar
chmod +x build.sh && ./build.sh
```

### 3. Install

```bash
cp -r ClaudeBar.app /Applications/
open /Applications/ClaudeBar.app
```

First launch: macOS will ask permission to access the Keychain — click **Always Allow**.

### Auto-start on login

**System Settings → General → Login Items → click「+」→ select ClaudeBar.app**

## Usage

- **Click** the `Claude ●●` icon in the menubar to open the usage panel
- **Left dot** = Session usage (5-hour window)
- **Right dot** = Weekly usage (7-day window)
- **⚙ Settings** → adjust auto-refresh interval
- **↺ Refresh** → manually fetch latest data

## How it works

ClaudeBar reads Claude Code's OAuth token from the macOS Keychain (`Claude Code-credentials`) and calls Anthropic's internal usage API (`/api/oauth/usage`) — the same endpoint that powers the usage dashboard at [claude.ai/settings/usage](https://claude.ai/settings/usage).

Your token never leaves your machine except for direct API calls to `api.anthropic.com`.

## Uninstall

```bash
osascript -e 'quit app "ClaudeBar"'
rm -rf /Applications/ClaudeBar.app
```

## License

MIT
