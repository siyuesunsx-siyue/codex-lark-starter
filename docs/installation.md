# Installation

This guide covers installing the full `codex-lark-starter` stack on
**Linux**, **WSL 2**, and **macOS**.

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Linux (Ubuntu / Debian)](#linux-ubuntu--debian)
- [WSL 2 (Windows)](#wsl-2-windows)
- [macOS](#macos)
- [Post-Install Verification](#post-install-verification)

---

## Prerequisites

Before starting, ensure you have:

1. A **Feishu / Lark** developer account with an app created in the
   [Feishu Developer Console](https://open.feishu.cn/app).
2. An **OpenAI API key** with access to the models you intend to use.
3. A machine with at least **4 GB RAM** and **2 vCPUs**.

---

## Linux (Ubuntu / Debian)

### Step 1: Run the platform installer

The `install-system.sh` script detects your package manager and installs
everything needed:

```bash
chmod +x install/install-system.sh
./install/install-system.sh
```

### Step 2: Install Node.js

```bash
chmod +x install/install-node.sh
./install/install-node.sh
```

### Step 3: Install Codex CLI

```bash
chmod +x install/install-codex.sh
./install/install-codex.sh
```

### Step 4: Validate the bridge

```bash
chmod +x install/install-bridge.sh
./install/install-bridge.sh
```

---

## WSL 2 (Windows)

### Step 1: Enable WSL 2

In an **administrator PowerShell**:

```powershell
wsl --install -d Ubuntu
```

Restart your machine if prompted.

### Step 2: Enter your WSL distribution and run the installer

```bash
chmod +x install/install-system.sh
./install/install-system.sh
```

This script also configures systemd and symlinks `detect-host-ip.sh` so
the bridge can reach the Windows host when needed.

### Step 3–4: Same as Linux

Continue with the Node.js, Codex CLI, and bridge install scripts above.

---

## macOS

### Step 1: Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Step 2: Install Node.js

```bash
brew install node@20
```

Or use the provided script:

```bash
chmod +x install/install-node.sh
./install/install-node.sh
```

### Step 3: Install Codex CLI

```bash
chmod +x install/install-codex.sh
./install/install-codex.sh
```

### Step 4: Validate the bridge

```bash
chmod +x install/install-bridge.sh
./install/install-bridge.sh
```

---

## Post-Install Verification

Run the smoke-test suite:

```bash
# Verify Node.js
node --version         # should print >= v20.0.0

# Verify npm
npm --version

# Verify Codex CLI
codex --version

# Verify bridge can start (it will fail without config, but should print the binary path)
./scripts/codex-bridge.sh status
```

### Configuration

Copy and populate the configuration:

```bash
cp examples/config.example.json config.json
```

Edit `config.json` with your Feishu app credentials and OpenAI API key.
**Do not commit `config.json`** — it is listed in `.gitignore`.

### Start

```bash
./scripts/codex-bridge.sh start
```

Check the logs:

```bash
tail -f logs/bridge.log
```
