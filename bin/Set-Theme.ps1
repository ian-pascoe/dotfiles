<#
.SYNOPSIS
  Sets the current theme by creating symbolic links to the selected theme's resources.
.DESCRIPTION
  This script links the specified theme from the user's .themes directory to the current theme configuration directory.
  It also updates themes for various applications including bat, btop, Flow Launcher, k9s, lsd, and yazi.
.PARAMETER ThemeName
  The name of the theme to set. HTML tags and spaces will be sanitized.
#>

param(
  [Parameter(Mandatory = $true)]
  [string]$ThemeName
)

$THEMES_DIR = "$env:USERPROFILE\.themes"
$CURRENT_THEME_DIR = "$env:XDG_CONFIG_HOME\theme"

$THEME_NAME = $ThemeName -replace '<[^>]+>', '' -replace ' ', '-'
$THEME_NAME = $THEME_NAME.ToLower()
$THEME_PATH = Join-Path $THEMES_DIR $THEME_NAME

if (-not (Test-Path $THEME_PATH -PathType Container)) {
  Write-Error "Theme '$THEME_NAME' does not exist in $THEMES_DIR"
  exit 1
}

Write-Host "Linking new theme: $THEME_NAME"
if (Test-Path $CURRENT_THEME_DIR) {
  Remove-Item $CURRENT_THEME_DIR -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType SymbolicLink -Path $CURRENT_THEME_DIR -Target $THEME_PATH | Out-Null

# bat
$BatThemesDir = "$env:BAT_CONFIG_DIR\themes"
if (-not (Test-Path $BatThemesDir)) {
  New-Item -ItemType Directory -Path $BatThemesDir | Out-Null
}
$BatTheme = Join-Path $CURRENT_THEME_DIR "bat.tmTheme"
$BatLink = Join-Path $BatThemesDir "current.tmTheme"
if (Test-Path $BatLink) {
  Remove-Item $BatLink -Force
}
New-Item -ItemType SymbolicLink -Path $BatLink -Target $BatTheme | Out-Null
bat cache --build

# btop
$BtopThemesDir = "$env:SCOOP\persist\btop\themes"
if (-not (Test-Path $BtopThemesDir)) {
  New-Item -ItemType Directory -Path $BtopThemesDir | Out-Null
}
$BtopTheme = Join-Path $CURRENT_THEME_DIR "btop.theme"
$BtopLink = Join-Path $BtopThemesDir "current.theme"
if (Test-Path $BtopLink) {
  Remove-Item $BtopLink -Force
}
New-Item -ItemType SymbolicLink -Path $BtopLink -Target $BtopTheme | Out-Null
scoop update -f btop && scoop cleanup -a

# flow launcher
$FlowLauncherThemesDir = "$env:SCOOP\persist\flow-launcher\UserData\Themes"
if (-not (Test-Path $FlowLauncherThemesDir)) {
  New-Item -ItemType Directory -Path $FlowLauncherThemesDir | Out-Null
}
$FlowLauncherTheme = Join-Path $CURRENT_THEME_DIR "flow-launcher.xaml"
if (Test-Path $FlowLauncherTheme) {
  $FlowLauncherLink = Join-Path $FlowLauncherThemesDir "current.xaml"
  if (Test-Path $FlowLauncherLink) {
    Remove-Item $FlowLauncherLink -Force
  }
  New-Item -ItemType SymbolicLink -Path $FlowLauncherLink -Target $FlowLauncherTheme | Out-Null

  # Restart Flow Launcher scheduled task
  Stop-Process -Name Flow.Launcher -Force -ErrorAction SilentlyContinue
  $taskName = "FlowLauncher"
  $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
  if ($task) {
    Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    Start-ScheduledTask -TaskName $taskName
    Write-Host "Restarted Flow Launcher" -ForegroundColor Cyan
  }
}

# k9s
$K9sSkinsDir = "$env:LOCALAPPDATA\k9s\skins"
if (-not (Test-Path $K9sSkinsDir)) {
  New-Item -ItemType Directory -Path $K9sSkinsDir | Out-Null
}
$K9sTheme = Join-Path $CURRENT_THEME_DIR "k9s.yaml"
$K9sLink = Join-Path $K9sSkinsDir "current.yaml"
if (Test-Path $K9sLink) {
  Remove-Item $K9sLink -Force
}
New-Item -ItemType SymbolicLink -Path $K9sLink -Target $K9sTheme | Out-Null

# lsd
$LsdColors = Join-Path $CURRENT_THEME_DIR "lsd.yaml"
$LsdLink = "$env:XDG_CONFIG_HOME\lsd\colors.yaml"
if (Test-Path $LsdLink) {
  Remove-Item $LsdLink -Force
}
New-Item -ItemType SymbolicLink -Path $LsdLink -Target $LsdColors | Out-Null

# yazi
$YaziTheme = Join-Path $CURRENT_THEME_DIR "yazi\theme.toml"
$YaziLink = "$env:YAZI_CONFIG_HOME\theme.toml"
if (Test-Path $YaziLink) {
  Remove-Item $YaziLink -Force
}
New-Item -ItemType SymbolicLink -Path $YaziLink -Target $YaziTheme | Out-Null
$YaziFlavorsDir = Join-Path $CURRENT_THEME_DIR "yazi\flavors"
if (Test-Path $YaziFlavorsDir -PathType Container) {
  $YaziConfigFlavors = "$env:YAZI_CONFIG_HOME\flavors"
  if (-not (Test-Path $YaziConfigFlavors)) {
    New-Item -ItemType Directory -Path $YaziConfigFlavors | Out-Null
  }
  Get-ChildItem -Path $YaziFlavorsDir | ForEach-Object {
    $FlavorLink = Join-Path $YaziConfigFlavors $_.Name
    if (Test-Path $FlavorLink) {
      Remove-Item $FlavorLink -Force
    }
    New-Item -ItemType SymbolicLink -Path $FlavorLink -Target $_.FullName | Out-Null
  }
} else {
  ya pkg install
}

# Reload YASB to apply the new theme
yasbc reload

& "$PSScriptRoot\Set-BG.ps1" -BackgroundIndex 1

wsl -d NixOS -- zsh -c "set-theme $ThemeName"
