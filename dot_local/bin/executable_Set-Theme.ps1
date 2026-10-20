<#
.SYNOPSIS
  Sets the current theme by creating symbolic links to the selected theme's resources.
.DESCRIPTION
  This script resolves a theme family or variant name to a theme variant (the same rules as the theme-resolve
  script, through the Themes module), then links that variant from the user's .themes directory to the current theme
  configuration directory. It also updates themes for various applications including bat, btop, GlazeWM, Helium (at
  its next start), k9s, lsd, Windows Terminal, yazi and YASB, and sets the Windows app and system appearance: light
  for a variant with a light.mode file. WezTerm watches the link itself.
  A family name uses the saved mode (~/.local/state/theme/mode, or under XDG_STATE_HOME) unless a mode is given.
  The mode is saved when one is given or a variant name is used; a family with no variant in the wanted mode falls
  back to its only variant and keeps the saved mode.
  The WSL distribution follows: it runs its own set-theme with the variant. A set-theme run in WSL starts this script
  in turn with -SkipWsl, so the theme can be switched from either side.
.PARAMETER ThemeName
  The theme family or variant to set. HTML tags and spaces will be sanitized.
.PARAMETER Mode
  light or dark; defaults to the saved mode.
.PARAMETER SkipWsl
  Leaves the WSL distribution alone (set when WSL's set-theme runs this script).
#>
param(
  [Parameter(Mandatory = $true)]
  [ArgumentCompleter({
      param($commandName, $parameterName, $wordToComplete)
      Get-ThemeFamily | ForEach-Object Name | Where-Object { $_ -like "$wordToComplete*" }
    })]
  [string]$ThemeName,

  [ValidateSet("light", "dark")]
  [string]$Mode,

  [switch]$SkipWsl
)

Import-Module (Join-Path $HOME Documents PowerShell Modules Themes) -ErrorAction Stop

$THEME_NAME = $ThemeName -replace '<[^>]+>', '' -replace ' ', '-'
$THEME_NAME = $THEME_NAME.ToLower()

$SavedMode = Get-SavedThemeMode
$WantedMode = if ($Mode) { $Mode } else { $SavedMode }

# Errors for unknown names come from Resolve-Theme.
$Resolved = Resolve-Theme $THEME_NAME $WantedMode
$IsFamily = Test-ThemeFamily $THEME_NAME

if (-not $IsFamily) {
  # A variant name decides the mode itself.
  if ($Mode -and $Mode -ne $Resolved.Mode) {
    Write-Warning "$($Resolved.Name) is a $($Resolved.Mode) variant; ignoring mode $Mode"
  }
  $NewMode = $Resolved.Mode
} elseif ($Resolved.Mode -eq $WantedMode) {
  $NewMode = $WantedMode
} else {
  Write-Host "$THEME_NAME has no $WantedMode variant; using $($Resolved.Name) and keeping mode $SavedMode"
  $NewMode = $SavedMode
}
if ($NewMode -ne $SavedMode) {
  Save-ThemeMode $NewMode
}

$THEME_NAME = $Resolved.Name
$THEME_PATH = $Resolved.Path
$CURRENT_THEME_DIR = Get-CurrentThemeLink
$env:CURRENT_THEME_DIR = $CURRENT_THEME_DIR
if ([Environment]::GetEnvironmentVariable("CURRENT_THEME_DIR", "User") -ne $CURRENT_THEME_DIR) {
  [Environment]::SetEnvironmentVariable("CURRENT_THEME_DIR", $CURRENT_THEME_DIR, "User")
}

Write-Host "Linking new theme: $THEME_NAME"
Set-ThemeLink -Target $THEME_PATH -Link $CURRENT_THEME_DIR

# Windows appearance follows the variant used, before apps reload.
$PersonalizeKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$UseLight = if ($Resolved.Mode -eq "light") { 1 } else { 0 }
Set-ItemProperty -Path $PersonalizeKey -Name AppsUseLightTheme -Value $UseLight -Type DWord
Set-ItemProperty -Path $PersonalizeKey -Name SystemUsesLightTheme -Value $UseLight -Type DWord

# bat
$BatConfigDir = if ($env:BAT_CONFIG_DIR) { $env:BAT_CONFIG_DIR } else { Join-Path (Get-ThemeConfigHome) "bat" }
$BatThemesDir = Join-Path $BatConfigDir "themes"
if (-not (Test-Path $BatThemesDir)) {
  New-Item -ItemType Directory -Path $BatThemesDir | Out-Null
}
$BatTheme = Join-Path $CURRENT_THEME_DIR "bat.tmTheme"
$BatLink = Join-Path $BatThemesDir "current.tmTheme"
Set-ThemeLink -Target $BatTheme -Link $BatLink
bat cache --build

# btop
$BtopThemesDir = "$env:SCOOP\apps\btop\current\themes"
if (-not (Test-Path $BtopThemesDir)) {
  New-Item -ItemType Directory -Path $BtopThemesDir | Out-Null
}
$BtopTheme = Join-Path $CURRENT_THEME_DIR "btop.theme"
$BtopLink = Join-Path $BtopThemesDir "current.theme"
Set-ThemeLink -Target $BtopTheme -Link $BtopLink

$BtopPersistedThemesDir = "$env:SCOOP\persist\btop\themes"
$BtopPersistedLink = Join-Path $BtopPersistedThemesDir "current.theme"
Set-ThemeLink -Target $BtopTheme -Link $BtopPersistedLink

# glazewm
$glazewmSettingsFile = Join-Path $HOME ".glzr\glazewm\config.yaml"
$glazewmSettingsContent = Get-Content $glazewmSettingsFile -Raw | ConvertFrom-Yaml
$glazewmThemeFile = Join-Path $CURRENT_THEME_DIR "glazewm.yaml"
$glazewmThemeContent = Get-Content $glazewmThemeFile -Raw | ConvertFrom-Yaml
$glazewmSettingsContent.window_effects.focused_window.border.color = $glazewmThemeContent.window_effects.focused_window.border.color
$glazewmSettingsContent.window_effects.other_windows.border.color = $glazewmThemeContent.window_effects.other_windows.border.color
$glazewmUpdatedSettingsContent = $glazewmSettingsContent | ConvertTo-Yaml
$glazewmUpdatedSettingsContent -replace "`r`n", "`n" | Set-Content $glazewmSettingsFile -NoNewline
glazewm command wm-reload-config

# helium: Helium loads the theme as an unpacked extension from this folder (Chromium resolves links when it loads
# one, so it is a copy). Without the folder Helium was never set up here; see dot_themes/docs/helium.md in the chezmoi
# source. Helium starts from its compiled Cached Theme.pak when there is one, so removing it makes the next start
# rebuild the theme from the new manifest.
$StateHome = Split-Path (Get-ThemeStateDir)
$HeliumThemeDir = Join-Path $StateHome "helium-theme"
$HeliumManifest = Join-Path $CURRENT_THEME_DIR "helium\manifest.json"
if ((Test-Path $HeliumThemeDir -PathType Container) -and (Test-Path $HeliumManifest)) {
  Copy-Item -Path $HeliumManifest -Destination (Join-Path $HeliumThemeDir "manifest.json") -Force
  Remove-Item -Path (Join-Path $HeliumThemeDir "Cached Theme.pak") -Force -ErrorAction SilentlyContinue
}

# k9s
$K9sSkinsDir = "$env:LOCALAPPDATA\k9s\skins"
if (-not (Test-Path $K9sSkinsDir)) {
  New-Item -ItemType Directory -Path $K9sSkinsDir | Out-Null
}
$K9sTheme = Join-Path $CURRENT_THEME_DIR "k9s.yaml"
$K9sLink = Join-Path $K9sSkinsDir "current.yaml"
Set-ThemeLink -Target $K9sTheme -Link $K9sLink

# lsd
$LsdColors = Join-Path $CURRENT_THEME_DIR "lsd.yaml"
$LsdLink = Join-Path (Get-ThemeConfigHome) "lsd\colors.yaml"
Set-ThemeLink -Target $LsdColors -Link $LsdLink

# windows terminal
$wtSettingsFile = Join-Path $env:SCOOP "persist\windows-terminal\settings\settings.json"
$wtSettingsContent = Get-Content $wtSettingsFile -Raw | ConvertFrom-Json
# change profiles.default.colorScheme to the new theme name
$wtSettingsContent.profiles.defaults.colorScheme = $THEME_NAME
# change theme to the new theme name
$wtSettingsContent.theme = $THEME_NAME
# Write back the updated settings
$wtUpdatedSettingsContent = $wtSettingsContent | ConvertTo-Json -Depth 99
$wtUpdatedSettingsContent -replace "`r`n", "`n" | Set-Content $wtSettingsFile -NoNewline

# yazi
$YaziTheme = Join-Path $CURRENT_THEME_DIR "yazi\theme.toml"
$YaziLink = "$env:YAZI_CONFIG_HOME\theme.toml"
Set-ThemeLink -Target $YaziTheme -Link $YaziLink

$YaziFlavorsDir = Join-Path $CURRENT_THEME_DIR "yazi\flavors"
if (Test-Path $YaziFlavorsDir -PathType Container) {
  $YaziConfigFlavors = "$env:YAZI_CONFIG_HOME\flavors"
  if (-not (Test-Path $YaziConfigFlavors)) {
    New-Item -ItemType Directory -Path $YaziConfigFlavors | Out-Null
  }
  Get-ChildItem -Path $YaziFlavorsDir | ForEach-Object {
    $FlavorLink = Join-Path $YaziConfigFlavors $_.Name
    Set-ThemeLink -Target $_.FullName -Link $FlavorLink
  }
}

& "$PSScriptRoot\Set-BG.ps1" -BackgroundIndex 1

# WSL follows; THEME_FROM_WINDOWS keeps its set-theme from starting this script again.
if (-not $SkipWsl -and (Get-Command wsl -ErrorAction SilentlyContinue)) {
  wsl -d (Get-ThemeWslDistro) -- env THEME_FROM_WINDOWS=1 zsh -c "set-theme '$THEME_NAME'"
}

# Reload YASB last: it restarts its process.
yasbc reload --silent
exit 0
