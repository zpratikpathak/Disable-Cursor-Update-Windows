# Cursor IDE Update Manager for Windows

A PowerShell script to centrally manage (disable or enable) automatic updates for the Cursor IDE on Windows systems.

**Last Updated**: August 2026

## 📚 Table of Contents

- [🚀 Quick Start](#-quick-start)
  - [One-Liner Run](#one-liner-run)
  - [Local Execution](#local-execution)
- [⚙️ What This Script Does](#️-what-this-script-does)
- [📋 Requirements](#-requirements)
- [🛠️ Features](#️-features)
- [📖 Usage Guide](#-usage-guide)
  - [Main Menu Options](#main-menu-options)
  - [Toggle Updates for a Single User](#toggle-updates-for-a-single-user)
  - [Disable Updates for All Users](#disable-updates-for-all-users)
  - [Enable Updates for All Users](#enable-updates-for-all-users)
- [🔧 How It Works](#-how-it-works)
- [⚠️ Important Notes](#️-important-notes)
- [❓ Troubleshooting](#-troubleshooting)
- [🗑️ Uninstallation](#️-uninstallation)
- [📄 License](#-license)

## 🚀 Quick Start

### One-Liner Run

**Run command into PowerShell **

```powershell
irm https://raw.githubusercontent.com/zpratikpathak/Disable-Cursor-Update-Windows/home/CursorUpdater.ps1 | iex
```

This command will:
- Execute it immediately
- Present you with the interactive menu

⚠️ If the script exist unexpectedly run this command in powershell

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm https://raw.githubusercontent.com/zpratikpathak/Disable-Cursor-Update-Windows/home/CursorUpdater.ps1 | iex
```


### Local Execution

**Download and run locally:**

```powershell
# Navigate to the directory containing CursorUpdater.ps1
cd C:\Path\To\CursorUpdate

# Run the script
.\CursorUpdater.ps1
```

**Requirements:**
- **Administrator privileges** (script will auto-elevate if needed)

## ⚙️ What This Script Does

This script provides a menu-driven interface to manage Cursor IDE updates by modifying the application's `settings.json` file for one or more users:

1. **Toggle updates for a single user** - Lists all available users and allows you to enable/disable updates individually
2. **Disable updates for all users** - Applies update restrictions across all user profiles
3. **Enable updates for all users** - Removes update restrictions for all user profiles

The script works by:
- **DISABLE**: Adds/sets `"update.mode": "none"` and `"update.enableWindowsBackgroundUpdates": false` in `settings.json`
- **ENABLE**: Removes those specific keys from `settings.json`

## 📋 Requirements

- **Windows 10 or later** (Windows 11 recommended)
- **Administrator privileges** - Script will auto-elevate via UAC prompt
- **Cursor IDE installed** - At least one user profile should have Cursor configured
- **PowerShell 5.1 or later** - Native to Windows 10+

## 🛠️ Features

✅ **Interactive Menu Interface** - User-friendly menu-driven control panel  
✅ **Auto-Elevation** - Automatically requests admin rights if needed  
✅ **Per-User Management** - Disable/enable updates for individual users  
✅ **Bulk Operations** - Apply settings to all users at once  
✅ **Status Display** - View current update status for each user  
✅ **Error Handling** - Graceful error handling with informative messages  
✅ **Color-Coded Output** - Easy-to-read colored console output  
✅ **Robust JSON Parsing** - Safely handles Cursor's settings.json file  

## 📖 Usage Guide

### Main Menu Options

When you run the script, you'll see the main control panel with these options:

```
*** Cursor IDE Updater Control Panel (settings.json method) ***

Please choose an option:
   [1] [TOGGLE] Disable/Enable Update for a SINGLE user
   [2] [DISABLE ALL] Disable Updates for ALL users
   [3] [ENABLE ALL] Enable Updates for ALL users
   [Q] [QUIT] Quit

Enter your choice
```

### Toggle Updates for a Single User

**Steps:**
1. Select option `[1]` from the main menu
2. The script displays all available user profiles with their current update status
3. Select the user number you want to toggle
4. The script automatically enables or disables updates based on the current status
5. Press Enter to return to the user selection menu
6. Press `C` to return to the main menu

**Status Indicators:**
- 🟢 **ENABLED** - Updates are currently allowed
- 🟡 **DISABLED** - Updates are currently blocked
- ⚪ **ENABLED (Default)** - No custom settings configured yet
- ❓ **UNKNOWN** - Error reading status

### Disable Updates for All Users

**Steps:**
1. Select option `[2]` from the main menu
2. The script applies update restrictions to all user profiles
3. Success messages will display for each user
4. Press Enter to return to the main menu

### Enable Updates for All Users

**Steps:**
1. Select option `[3]` from the main menu
2. The script removes update restrictions from all user profiles
3. Success messages will display for each user
4. Press Enter to return to the main menu

## 🔧 How It Works

### File Location

The script modifies Cursor's settings file located at:

```
C:\Users\<USERNAME>\AppData\Roaming\Cursor\User\settings.json
```

### Disable Logic

When disabling updates, the script:
1. Locates or creates the `settings.json` file
2. Parses the JSON content
3. Sets `"update.mode": "none"`
4. Sets `"update.enableWindowsBackgroundUpdates": false`
5. Saves the modified JSON back to the file

### Enable Logic

When enabling updates, the script:
1. Locates the `settings.json` file
2. Parses the JSON content
3. Removes the `"update.mode"` key
4. Removes the `"update.enableWindowsBackgroundUpdates"` key
5. Saves the modified JSON back to the file

## ⚠️ Important Notes

- **Administrator Required**: The script automatically requests admin privileges. You'll see a UAC prompt.
- **Cursor Must Run**: Changes take effect when Cursor reads its settings.json file. Restart Cursor after making changes.
- **JSON Comments**: The script cannot parse settings.json files that contain JSON comments (`//`). Remove comments if encountered.
- **System Users Excluded**: System-level users (Default, Public, All Users) are automatically excluded from the user list.
- **Backup Recommended**: Consider backing up your `settings.json` before running this script on critical systems.

## ❓ Troubleshooting

### "This script requires Administrator privileges"

The script will automatically attempt to elevate itself. If you see a UAC (User Account Control) prompt:
- Click "Yes" to allow the script to run as Administrator
- If blocked by policy, run PowerShell as Administrator manually first

### "Cannot parse settings.json - contains comments"

**Solution**: Remove JSON comments from the settings.json file:
1. Open `C:\Users\<USERNAME>\AppData\Roaming\Cursor\User\settings.json` in a text editor
2. Remove any lines starting with `//`
3. Save the file and try again

### Changes not taking effect

**Solution**: Restart Cursor IDE:
1. Close Cursor completely
2. Open Cursor again
3. Your update settings should now be applied

### "No user profiles found to manage"

**Possible causes**:
- Cursor is not installed for any user
- User profiles are in non-standard locations
- Insufficient permissions

**Solution**: Ensure Cursor is installed and run the script with full Administrator privileges

### Script exits unexpectedly

**Solution**: 
1. Open PowerShell as Administrator
2. Run the script directly:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   .\CursorUpdater.ps1
   ```

## 🗑️ Uninstallation

There's nothing to uninstall! This script doesn't modify system files or install applications. To revert changes:

1. Run the script again
2. Select `[3] [ENABLE ALL]` to re-enable updates for all users
3. Or manually delete the script file

To restore Cursor to default update settings:
1. Run the script as Administrator
2. Select `[3] [ENABLE ALL]` to enable updates for all users

## 📄 License

This project is licensed under the MIT License. See the LICENSE file for details.

---

**Repository**: [zpratikpathak/Disable-Cursor-Update-Windows](https://github.com/zpratikpathak/Disable-Cursor-Update-Windows)  
**Author**: Pratik Pathak  
**Version**: 2.3  
**Last Updated**: August 2026
