<#
.SYNOPSIS
  A PowerShell script to centrally manage (disable or enable) the
  automatic updates for the Cursor IDE on Windows 11.

.DESCRIPTION
  This script provides a menu-driven interface to:
  1. Toggle updates for a single specified user (lists all users).
  2. Disable updates for all users.
  3. Enable updates for all users.

  [NEW METHOD]
  This script now works by modifying the 'settings.json' file for each user.
  - DISABLE: Adds/sets "update.mode": "none" and "update.enableWindowsBackgroundUpdates": false.
  - ENABLE: Removes those specific keys from the settings.json file.

.NOTES
  Author: Gemini
  Version: 2.3 (Improved UI loop)
  REQUIRES: Administrator privileges to modify other user profiles.
#>

# --- Admin Check & Self-Elevation ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script requires Administrator privileges. Attempting to relaunch as Admin..."
    Write-Host "Please approve the UAC prompt." -ForegroundColor Yellow
    
    # Relaunch the script with Admin rights
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -File `"$($MyInvocation.MyCommand.Path)`""
    
    # Exit the current non-admin session
    exit
}

# --- Configuration ---
# "pratik" has been removed from this list as requested.
$ExcludedUsers = @("Default", "Public", "Default User", "All Users")
$BaseUserPath = "C:\Users"
# Standard path for Cursor's settings file
$SettingsJsonPath = "AppData\Roaming\Cursor\User\settings.json"

# --- Colors ---
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorError = "Red"
$ColorWarning = "Yellow"
$ColorMenu = "Magenta"

# --- Function Definitions ---

function Get-UserProfiles {
    <#
    .SYNOPSIS
      Gets all user profile folders, excluding system/specified users.
    #>
    try {
        $UserProfiles = Get-ChildItem -Path $BaseUserPath -Directory -ErrorAction Stop | Where-Object { $_.Name -notin $ExcludedUsers }
        return $UserProfiles
    } catch {
        Write-Host "[ERROR] Critical Error: Could not read user profiles from '$BaseUserPath'. $_" -ForegroundColor $ColorError
        return $null
    }
}

function Get-CursorUpdateStatus($Username) {
    <#
    .SYNOPSIS
      Checks the update status for a user by reading their settings.json.
    .RETURNS
      [string] "DISABLED", "ENABLED", "ENABLED (Default)", or "UNKNOWN"
    #>
    $SettingsFile = Join-Path -Path (Join-Path -Path $BaseUserPath -ChildPath $Username) -ChildPath $SettingsJsonPath
    try {
        if (-not (Test-Path $SettingsFile)) {
            return "ENABLED (Default)"
        }
        
        $JsonString = Get-Content -Path $SettingsFile -Raw -ErrorAction Stop
        if ($JsonString -match "//") {
            return "UNKNOWN (JSON has comments)"
        }
        if ([string]::IsNullOrWhiteSpace($JsonString)) {
            return "ENABLED (Default)"
        }

        $Settings = $JsonString | ConvertFrom-Json -ErrorAction Stop
        
        if ($Settings.'update.mode' -eq 'none' -and $Settings.'update.enableWindowsBackgroundUpdates' -eq $false) {
            return "DISABLED"
        } else {
            return "ENABLED"
        }
    } catch {
        return "UNKNOWN (Error reading file)"
    }
}


function Disable-CursorUpdate($Username) {
    <#
    .SYNOPSIS
      Disables Cursor updates for a specific user by editing settings.json.
    #>
    Write-Host "`n  [INFO] Attempting to DISABLE updates for: $Username" -ForegroundColor $ColorInfo
    $SettingsFile = Join-Path -Path (Join-Path -Path $BaseUserPath -ChildPath $Username) -ChildPath $SettingsJsonPath
    $SettingsDir = Split-Path $SettingsFile -Parent

    try {
        # Ensure the directory exists
        if (-not (Test-Path $SettingsDir)) {
            Write-Host "    [WARN] Settings directory not found, creating it..." -ForegroundColor $ColorWarning
            New-Item -Path $SettingsDir -ItemType Directory -Force | Out-Null
        }

        # Load existing settings or create a new object
        $Settings = $null
        if (Test-Path $SettingsFile) {
            Write-Host "    [OK] Found 'settings.json'." -ForegroundColor $ColorInfo
            $JsonString = Get-Content -Path $SettingsFile -Raw -ErrorAction Stop
            
            # Check for comments (which invalidates JSON)
            if ($JsonString -match "//") {
                Write-Host "    [ERROR] 'settings.json' for $Username contains comments (//) and cannot be safely parsed." -ForegroundColor $ColorError
                Write-Host "    [INFO] Please remove comments from the file and try again. Skipping user." -ForegroundColor $ColorInfo
                return
            }

            # Handle empty file case
            if ([string]::IsNullOrWhiteSpace($JsonString)) {
                $Settings = New-Object -TypeName PSObject
            } else {
                $Settings = $JsonString | ConvertFrom-Json -ErrorAction Stop
            }
        } else {
            Write-Host "    [INFO] 'settings.json' not found, will create it." -ForegroundColor $ColorInfo
            $Settings = New-Object -TypeName PSObject
        }

        # Check if already disabled
        if ($Settings.'update.mode' -eq 'none' -and $Settings.'update.enableWindowsBackgroundUpdates' -eq $false) {
            Write-Host "    [INFO] Updates are already DISABLED for $Username." -ForegroundColor $ColorInfo
            return
        }

        # Apply settings
        $Settings | Add-Member -MemberType NoteProperty -Name "update.mode" -Value "none" -Force
        $Settings | Add-Member -MemberType NoteProperty -Name "update.enableWindowsBackgroundUpdates" -Value $false -Force
        Write-Host "    [OK] Applied 'update.mode: none'." -ForegroundColor $ColorSuccess
        Write-Host "    [OK] Applied 'update.enableWindowsBackgroundUpdates: false'." -ForegroundColor $ColorSuccess

        # Save settings back to file
        $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsFile -Encoding UTF8 -Force
        Write-Host "  [SUCCESS] Successfully DISABLED updates for $Username." -ForegroundColor $ColorSuccess

    } catch {
        Write-Host "    [ERROR] An error occurred while disabling updates for ${Username}: $_" -ForegroundColor $ColorError
        if ($_.Exception.Message -like "*Invalid JSON primitive*") {
            Write-Host "    [HINT] The 'settings.json' file for $Username might be corrupt." -ForegroundColor $ColorWarning
        }
    }
}

function Enable-CursorUpdate($Username) {
    <#
    .SYNOPSIS
      Enables Cursor updates for a specific user by editing settings.json.
    #>
    Write-Host "`n  [INFO] Attempting to ENABLE updates for: $Username" -ForegroundColor $ColorInfo
    $SettingsFile = Join-Path -Path (Join-Path -Path $BaseUserPath -ChildPath $Username) -ChildPath $SettingsJsonPath

    try {
        # Check if file exists
        if (-not (Test-Path $SettingsFile)) {
            Write-Host "    [INFO] 'settings.json' not found for $Username. No action taken." -ForegroundColor $ColorInfo
            return
        }
        
        Write-Host "    [OK] Found 'settings.json'." -ForegroundColor $ColorInfo
        $JsonString = Get-Content -Path $SettingsFile -Raw -ErrorAction Stop

        # Check for comments
        if ($JsonString -match "//") {
            Write-Host "    [ERROR] 'settings.json' for $Username contains comments (//) and cannot be safely parsed." -ForegroundColor $ColorError
            Write-Host "    [INFO] Please remove comments from the file and try again. Skipping user." -ForegroundColor $ColorInfo
            return
        }

        # Handle empty file
        if ([string]::IsNullOrWhiteSpace($JsonString)) {
            Write-Host "    [INFO] 'settings.json' is empty. Updates are already ENABLED (default)." -ForegroundColor $ColorInfo
            return
        }

        $Settings = $JsonString | ConvertFrom-Json -ErrorAction Stop

        # Check if settings are present
        $Props = $Settings.PSObject.Properties
        if (-not $Props.'update.mode' -and -not $Props.'update.enableWindowsBackgroundUpdates') {
            Write-Host "    [INFO] Update settings not found in file. Updates are already ENABLED (default)." -ForegroundColor $ColorInfo
            return
        }

        $ChangesMade = $false
        # Remove properties
        if ($Props.'update.mode') {
            $Props.Remove('update.mode')
            Write-Host "    [OK] Removed 'update.mode' setting." -ForegroundColor $ColorSuccess
            $ChangesMade = $true
        }
        if ($Props.'update.enableWindowsBackgroundUpdates') {
            $Props.Remove('update.enableWindowsBackgroundUpdates')
            Write-Host "    [OK] Removed 'update.enableWindowsBackgroundUpdates' setting." -ForegroundColor $ColorSuccess
            $ChangesMade = $true
        }

        # Save settings back to file
        if ($ChangesMade) {
            $Settings | ConvertTo-Json -Depth 10 | Set-Content -Path $SettingsFile -Encoding UTF8 -Force
            Write-Host "  [SUCCESS] Successfully ENABLED updates for $Username." -ForegroundColor $ColorSuccess
        }

    } catch {
        Write-Host "    [ERROR] An error occurred while enabling updates for ${Username}: $_" -ForegroundColor $ColorError
        if ($_.Exception.Message -like "*Invalid JSON primitive*") {
            Write-Host "    [HINT] The 'settings.json' file for $Username might be corrupt." -ForegroundColor $ColorWarning
        }
    }
}

# --- Main Menu Loop ---
while ($true) {
    Clear-Host
    Write-Host "`n" + ("-" * 60) -ForegroundColor $ColorMenu
    Write-Host " *** Cursor IDE Updater Control Panel (settings.json method) ***" -ForegroundColor $ColorMenu
    Write-Host ("-" * 60) -ForegroundColor $ColorMenu
    Write-Host " Please choose an option:" -ForegroundColor "White"
    Write-Host "   [1] [TOGGLE] Disable/Enable Update for a SINGLE user" -ForegroundColor "Cyan"
    Write-Host "   [2] [DISABLE ALL] Disable Updates for ALL users" -ForegroundColor "Yellow"
    Write-Host "   [3] [ENABLE ALL] Enable Updates for ALL users" -ForegroundColor "Green"
    Write-Host "   [Q] [QUIT] Quit" -ForegroundColor "Red"
    Write-Host "`n"
    $choice = Read-Host " Enter your choice"

    switch ($choice) {
        "1" {
            # --- Single User Toggle Loop ---
            $ErrorMessage = $null # Initialize error variable
            while ($true) {
                Clear-Host
                Write-Host "`n" + ("-" * 60) -ForegroundColor $ColorMenu
                Write-Host " *** Single User Toggle ***" -ForegroundColor $ColorMenu
                Write-Host ("-" * 60) -ForegroundColor $ColorMenu

                # --- NEW: Display Error from last loop ---
                if ($ErrorMessage) {
                    Write-Host "`n$ErrorMessage" -ForegroundColor $ColorError
                    $ErrorMessage = $null # Clear the error
                }

                # --- Single User Toggle ---
                Write-Host "`n  [INFO] Getting user profile statuses..." -ForegroundColor $ColorInfo
                $profiles = Get-UserProfiles
                if ($null -eq $profiles -or $profiles.Count -eq 0) {
                    Write-Host "[ERROR] No user profiles found to manage." -ForegroundColor $ColorError
                    Write-Host "`n"
                    Read-Host "Press Enter to return to the main menu..."
                    break
                }

                # Create a list of users and their status
                $userStatusList = @()
                foreach ($profile in $profiles) {
                    $status = Get-CursorUpdateStatus $profile.Name
                    $userStatusList += [PSCustomObject]@{
                        Name   = $profile.Name
                        Status = $status
                    }
                }

                # Display the list
                Write-Host " Please select a user to toggle their update status:" -ForegroundColor "White"
                for ($i = 0; $i -lt $userStatusList.Count; $i++) {
                    $user = $userStatusList[$i]
                    $statusColor = if ($user.Status -eq "DISABLED") { $ColorWarning } else { $ColorSuccess }
                    Write-Host ("   [{0}] {1,-20} (Status: {2})" -f ($i + 1), $user.Name, $user.Status) -ForegroundColor $statusColor
                }
                Write-Host "   [C] Cancel (Return to Main Menu)" -ForegroundColor "Red"

                $userChoice = Read-Host "`n  Enter your choice"

                if ($userChoice -eq "C" -or $userChoice -eq "c") {
                    break # Back to main menu
                }

                # Validate input
                if ($userChoice -match "^\d+$" -and [int]$userChoice -ge 1 -and [int]$userChoice -le $userStatusList.Count) {
                    $selectedUser = $userStatusList[[int]$userChoice - 1]
                    
                    Write-Host "`n  Toggling status for: $($selectedUser.Name)" -ForegroundColor $ColorMenu
                    
                    # Toggle the status
                    if ($selectedUser.Status -eq "DISABLED") {
                        Enable-CursorUpdate $selectedUser.Name
                    } else {
                        # This will catch "ENABLED", "ENABLED (Default)", and "UNKNOWN"
                        Disable-CursorUpdate $selectedUser.Name
                    }
                    # Pause to show success/error message from enable/disable function
                    Write-Host "`n"
                    Read-Host "Press Enter to continue..."
                } else {
                    $ErrorMessage = "[ERROR] Invalid selection."
                }
                
                # Removed the Read-Host from here
            }
        }
        "2" {
            # --- Disable All ---
            Write-Host "`n[DISABLE ALL] Disabling updates for ALL users..." -ForegroundColor $ColorWarning
            $profiles = Get-UserProfiles
            if ($null -eq $profiles) {
                Write-Host "[ERROR] Could not retrieve user profiles." -ForegroundColor $ColorError
            } else {
                foreach ($profile in $profiles) {
                    Disable-CursorUpdate $profile.Name
                }
                Write-Host "`n[SUCCESS] All-user disable process complete." -ForegroundColor $ColorSuccess
            }
            Write-Host "`n"
            Read-Host "Press Enter to return to the menu..."
        }
        "3" {
            # --- Enable All ---
            Write-Host "`n[ENABLE ALL] Enabling updates for ALL users..." -ForegroundColor $ColorSuccess
            $profiles = Get-UserProfiles
            if ($null -eq $profiles) {
                Write-Host "[ERROR] Could not retrieve user profiles." -ForegroundColor $ColorError
            } else {
                foreach ($profile in $profiles) {
                    Enable-CursorUpdate $profile.Name
                }
                Write-Host "`n[SUCCESS] All-all-user enable process complete." -ForegroundColor $ColorSuccess
            }
            Write-Host "`n"
            Read-Host "Press Enter to return to the menu..."
        }
        "Q" {
            # --- Quit ---
            Write-Host "`nGoodbye!" -ForegroundColor $ColorInfo
            # No 'break' here, it will be caught by the check below
        }
        default {
            Write-Host "`n[ERROR] Invalid choice. Please select 1, 2, 3, or Q." -ForegroundColor $ColorError
            Write-Host "`n"
            Read-Host "Press Enter to return to the menu..."
        }
    }

    # --- FIX ---
    # Check if the user chose to quit, and if so, break out of the while loop
    # before the "Press Enter" prompt.
    if ($choice -eq "Q" -or $choice -eq "q") {
        break
    }
}


