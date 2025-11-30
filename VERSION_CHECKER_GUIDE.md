# Version Checker Setup Guide

## How It Works

The version checker automatically compares your local script version with the latest version on GitHub when the server restarts.

## Setup Instructions

### 1. Update GitHub URL

In both `server.lua` files, replace the placeholder URL with your actual GitHub repository:

**ESX Version:**
```lua
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/solar_freeshop-esx/version.json"
```

**QB Version:**
```lua
local GITHUB_RAW_URL = "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/solar_freeshop-qb/version.json"
```

Replace:
- `YOUR_USERNAME` with your GitHub username
- `YOUR_REPO` with your repository name

### 2. Update Version

When you release a new version:

1. Update `CURRENT_VERSION` in `server.lua`:
```lua
local CURRENT_VERSION = "1.0.1"  -- Change this
```

2. Update `version.json`:
```json
{
  "version": "1.0.1",
  "changelog": "Fixed bugs and improved performance"
}
```

3. Update `fxmanifest.lua`:
```lua
version '1.0.1'
```

4. Commit and push to GitHub

### 3. Server Output

When the server restarts:

**If update is available:**
```
========================================
[VERSION CHECK] UPDATE AVAILABLE!
Current Version: 1.0.0
Latest Version: 1.0.1
Changelog: Fixed bugs and improved performance
Update at: https://github.com/YOUR_USERNAME/YOUR_REPO
========================================
```

**If up to date:**
```
[VERSION CHECK] You are running the latest version (1.0.0)
```

## Version Format

Use semantic versioning: `MAJOR.MINOR.PATCH`
- MAJOR: Breaking changes
- MINOR: New features (backward compatible)
- PATCH: Bug fixes

Example: `1.2.3`
