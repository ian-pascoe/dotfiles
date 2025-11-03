#Requires -RunAsAdministrator

param(
  [string]$CustomProgramDir = "$env:SYSTEMDRIVE\Program Files",
  [string]$ScoopDir = "$env:USERPROFILE\scoop",
  [switch]$SkipWindows = $false,
  [switch]$SkipWSL = $false,
  [switch]$SkipTheme = $false
)

# source the powershell profile
. "$PSScriptRoot/PowerShell/profile.ps1"

if (-not $SkipWindows) {
  Update-Powershell

  # setup important env vars
  Set-EnvironmentVariable -Name CustomProgramFiles -Value $CustomProgramDir -Persist
  Set-EnvironmentVariable -Name HOME -Value "$env:USERPROFILE" -Persist
  if ($env:PATH -notlike "*$env:CustomProgramFiles\PowerShell\current*") {
    Set-EnvironmentVariable -Name PATH -Value "$env:CustomProgramFiles\PowerShell\current;$env:PATH" -Persist
  }
  if ($env:PATH -notlike "*$env:USERPROFILE\.local\bin*") {
    Set-EnvironmentVariable -Name PATH -Value "$env:USERPROFILE\.local\bin;$env:PATH" -Persist
  }
  Set-EnvironmentVariable -Name POWERSHELL_TELEMETRY_OPTOUT -Value "true" -Persist
  if ($env:PSModulePath -notlike "*$env:USERPROFILE\Documents\PowerShell\Modules*") {
    Set-EnvironmentVariable -Name PSModulePath -Value "$env:USERPROFILE\Documents\PowerShell\Modules;$env:PSModulePath" -Persist
  }
  if ($env:PSModulePath -notlike "*$env:USERPROFILE\Documents\WindowsPowerShell\Modules*") {
    Set-EnvironmentVariable -Name PSModulePath -Value "$env:USERPROFILE\Documents\WindowsPowerShell\Modules;$env:PSModulePath" -Persist
  }
  if ($env:PSModulePath -notlike "*$CustomProgramDir\PowerShell\Modules*") {
    Set-EnvironmentVariable -Name PSModulePath -Value "$CustomProgramDir\PowerShell\Modules;$env:PSModulePath" -Persist
  }
  Set-EnvironmentVariable -Name XDG_BIN_HOME -Value "$env:USERPROFILE\.local\bin" -Persist
  Set-EnvironmentVariable -Name XDG_CACHE_HOME -Value "$env:USERPROFILE\.cache" -Persist
  Set-EnvironmentVariable -Name XDG_CONFIG_HOME -Value "$env:USERPROFILE\.config" -Persist
  Set-EnvironmentVariable -Name XDG_DATA_HOME -Value "$env:USERPROFILE\.local\share" -Persist
  Set-EnvironmentVariable -Name XDG_DESKTOP_DIR -Value "$env:USERPROFILE\Desktop" -Persist
  Set-EnvironmentVariable -Name XDG_DOWNLOAD_DIR -Value "$env:USERPROFILE\Downloads" -Persist

  # link powershell profile/config
  if (-not (Test-Path "$env:USERPROFILE\Documents\PowerShell")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\Documents\PowerShell"
  }
  New-Symlink -Target "$PSScriptRoot\PowerShell\profile.ps1" -Link "$env:USERPROFILE\Documents\PowerShell\profile.ps1" -Force
  New-Symlink -Target "$PSScriptRoot\PowerShell\powershell.config.json" -Link "$env:USERPROFILE\Documents\PowerShell\powershell.config.json" -Force

  if (-not (Test-Path "$env:USERPROFILE\Documents\WindowsPowerShell")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\Documents\WindowsPowerShell"
  }
  New-Symlink -Target "$PSScriptRoot\WindowsPowerShell\profile.ps1" -Link "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1" -Force

  # setup local bin
  if (-not (Test-Path "$env:XDG_BIN_HOME")) {
    New-Item -ItemType Directory -Path "$env:XDG_BIN_HOME"
  }

  $scripts = Get-ChildItem -Path "$PSScriptRoot\..\bin" -Filter *.ps1
  foreach ($script in $scripts) {
    New-Symlink -Target $script.FullName -Link "$env:XDG_BIN_HOME\$($script.Name)" -Force
  }

  # setup scoop
  if (-not (Test-Command -commandName scoop)) {
    Set-EnvironmentVariable -Name SCOOP -Value $ScoopDir -Persist
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-Expression "& {$(Invoke-RestMethod -Uri https://get.scoop.sh)} -RunAsAdmin"
  } else {
    if ($env:SCOOP -ne $ScoopDir) {
      Write-Host "WARNING: Existing SCOOP environment variable does not match -ScoopDir. No changes will be made to the scoop path." -ForegroundColor Yellow
    }
  }

  # install packages
  scoop import "$PSScriptRoot\..\config\scoop\scoopfile.json"
  scoop update -a && scoop cleanup -a

  # configure apps/links
  New-Symlink -Target "$PSScriptRoot\..\themes" -Link "$env:USERPROFILE\.themes" -Force

  if (-not (Test-Path "$env:XDG_CONFIG_HOME")) {
    New-Item -ItemType Directory -Path "$env:XDG_CONFIG_HOME"
  }

  # alacritty
  if (-not (Test-Path "$env:APPDATA\alacritty")) {
    New-Item -ItemType Directory -Path "$env:APPDATA\alacritty"
  }
  New-Symlink -Target "$PSScriptRoot\..\config\alacritty\alacritty.toml" -Link "$env:APPDATA\alacritty\alacritty.toml" -Force

  # bat
  Set-EnvironmentVariable -Name BAT_CONFIG_DIR -Value "$env:XDG_CONFIG_HOME\bat" -Persist
  New-Symlink -Target "$PSScriptRoot\..\config\bat" -Link "$env:BAT_CONFIG_DIR" -Force

  # btop
  New-Symlink -Target "$PSScriptRoot\..\config\btop" -Link "$env:SCOOP\persist\btop" -Force
  New-Symlink -Target "$PSScriptRoot\..\config\btop" -Link "$env:XDG_CONFIG_HOME\btop" -Force
  # Update btop to apply the changes
  scoop update --force btop && scoop cleanup -a

  # k9s
  New-Symlink -Target "$PSScriptRoot\..\config\k9s" -Link "$env:LOCALAPPDATA\k9s" -Force

  # lsd
  New-Symlink -Target "$PSScriptRoot\..\config\lsd" -Link "$env:XDG_CONFIG_HOME\lsd" -Force

  # scoop
  New-Symlink -Target "$PSScriptRoot\..\config\scoop" -Link "$env:XDG_CONFIG_HOME\scoop" -Force

  # starship
  New-Symlink -Target "$PSScriptRoot\..\config\starship.toml" -Link "$env:XDG_CONFIG_HOME\starship.toml" -Force

  # winfetch
  Set-EnvironmentVariable -Name WINFETCH_CONFIG_PATH -Value "$env:XDG_CONFIG_HOME\winfetch\config.ps1" -Persist
  New-Symlink -Target "$PSScriptRoot\..\config\winfetch" -Link (& Split-Path "$env:WINFETCH_CONFIG_PATH" -Parent) -Force

  # apps with more involved setup
  & "$PSScriptRoot\PowerShell\Scripts\Setup-AutoHotkey.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-FlowLauncher.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-GlazeWM.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-VcXsrv.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-YASB.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-Yazi.ps1"
}

if (-not $SkipWSL) {
  New-Symlink -Target "$PSScriptRoot\..\Windows\wslconfig" -Link "$env:USERPROFILE\.wslconfig" -Force
}

if (-not $SkipTheme) {
  if (-not (Test-Path "$env:USERPROFILE\.config\theme")) {
    Write-Host "Linking Rose Pine (default) theme"
    Set-Theme "Rose-Pine"
  } else {
    Write-Host "Reapplying theme"
    $themeDir = (Get-Item "$env:USERPROFILE\.config\theme").Target
    $theme = Split-Path $themeDir -Leaf
    Set-Theme $theme
  }
} 
