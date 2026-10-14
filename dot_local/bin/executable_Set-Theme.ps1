<#
.SYNOPSIS
  Sets the current theme by creating symbolic links to the selected theme's resources.
.DESCRIPTION
  This script resolves a theme family or variant name to a theme variant (the same rules as the theme-resolve
  script), then links that variant from the user's .themes directory to the current theme configuration directory.
  It also updates themes for various applications including bat, btop, k9s, lsd, and yazi, and sets the Windows
  app and system appearance: light for a variant with a light.mode file.
  A family name uses the saved mode (~/.local/state/theme/mode, or under XDG_STATE_HOME) unless a mode is given.
  The mode is saved when one is given or a variant name is used; a family with no variant in the wanted mode falls
  back to its only variant and keeps the saved mode.
.PARAMETER ThemeName
  The theme family or variant to set. HTML tags and spaces will be sanitized.
.PARAMETER Mode
  light or dark; defaults to the saved mode.
#>
param(
  [Parameter(Mandatory = $true)]
  [ArgumentCompleter({
      param($commandName, $parameterName, $wordToComplete)
      if (-not $env:THEMES_DIR) { return }
      Get-ChildItem -Path $env:THEMES_DIR -Directory | ForEach-Object {
        $familyFile = Join-Path $_.FullName "family"
        $family = if (Test-Path $familyFile) { "$(Get-Content $familyFile -TotalCount 1)".Trim() }
        if ($family) { $family } else { $_.Name }
      } | Sort-Object -Unique | Where-Object { $_ -like "$wordToComplete*" }
    })]
  [string]$ThemeName,

  [ValidateSet("light", "dark")]
  [string]$Mode
)

$CURRENT_THEME_DIR = "$env:XDG_CONFIG_HOME\theme"
Set-EnvironmentVariable -Name CURRENT_THEME_DIR -Value $CURRENT_THEME_DIR -Persist

$THEME_NAME = $ThemeName -replace '<[^>]+>', '' -replace ' ', '-'
$THEME_NAME = $THEME_NAME.ToLower()

# Resolve the name like the theme-resolve script: a variant is a folder in .themes, light when it has a light.mode
# file; its family is named in its family file, or is the folder name. A family name wins over a folder name.
$StateHome = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $HOME ".local\state" }
$ModeFile = Join-Path $StateHome "theme\mode"
$SavedMode = if ((Test-Path $ModeFile) -and ("$(Get-Content $ModeFile -TotalCount 1)".Trim() -eq "light")) { "light" } else { "dark" }
$WantedMode = if ($Mode) { $Mode } else { $SavedMode }

$Variants = Get-ChildItem -Path $env:THEMES_DIR -Directory | ForEach-Object {
  $familyFile = Join-Path $_.FullName "family"
  $family = if (Test-Path $familyFile) { "$(Get-Content $familyFile -TotalCount 1)".Trim() }
  [pscustomobject]@{
    Name   = $_.Name
    Family = if ($family) { $family } else { $_.Name }
    Mode   = if (Test-Path (Join-Path $_.FullName "light.mode")) { "light" } else { "dark" }
  }
}
$FamilyMembers = @($Variants | Where-Object { $_.Family -eq $THEME_NAME })
if ($FamilyMembers) {
  $Resolved = $FamilyMembers | Where-Object { $_.Mode -eq $WantedMode } | Select-Object -First 1
  if (-not $Resolved) { $Resolved = $FamilyMembers | Select-Object -First 1 }
} else {
  $Resolved = $Variants | Where-Object { $_.Name -eq $THEME_NAME } | Select-Object -First 1
}
if (-not $Resolved) {
  Write-Error "Theme '$THEME_NAME' is not a family or variant in $env:THEMES_DIR"
  exit 1
}

if (-not $FamilyMembers) {
  # A variant name decides the mode itself.
  if ($Mode -and $Mode -ne $Resolved.Mode) {
    Write-Warning "$($Resolved.Name) is a $($Resolved.Mode) variant; ignoring mode $Mode"
  }
  $NewMode = $Resolved.Mode
} elseif ($Resolved.Mode -eq $WantedMode) {
  $NewMode = $WantedMode
} else {
  Write-Log -Message "$THEME_NAME has no $WantedMode variant; using $($Resolved.Name) and keeping mode $SavedMode" -Level Info
  $NewMode = $SavedMode
}
if ($NewMode -ne $SavedMode) {
  New-Item -ItemType Directory -Force -Path (Split-Path $ModeFile) | Out-Null
  [IO.File]::WriteAllText($ModeFile, "$NewMode`n")
}

$THEME_NAME = $Resolved.Name
$THEME_PATH = Join-Path $env:THEMES_DIR $THEME_NAME

Write-Log -Message "Linking new theme: $THEME_NAME" -Level Info
New-Symlink -Target $THEME_PATH -Link $CURRENT_THEME_DIR -Force

# Windows appearance follows the variant used, before apps reload.
$PersonalizeKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$UseLight = if ($Resolved.Mode -eq "light") { 1 } else { 0 }
Set-ItemProperty -Path $PersonalizeKey -Name AppsUseLightTheme -Value $UseLight -Type DWord
Set-ItemProperty -Path $PersonalizeKey -Name SystemUsesLightTheme -Value $UseLight -Type DWord

# bat
$BatThemesDir = "$env:BAT_CONFIG_DIR\themes"
if (-not (Test-Path $BatThemesDir)) {
  New-Item -ItemType Directory -Path $BatThemesDir | Out-Null
}
$BatTheme = Join-Path $CURRENT_THEME_DIR "bat.tmTheme"
$BatLink = Join-Path $BatThemesDir "current.tmTheme"
New-Symlink -Target $BatTheme -Link $BatLink -Force
bat cache --build

# btop
$BtopThemesDir = "$env:SCOOP\apps\btop\current\themes"
if (-not (Test-Path $BtopThemesDir)) {
  New-Item -ItemType Directory -Path $BtopThemesDir | Out-Null
}
$BtopTheme = Join-Path $CURRENT_THEME_DIR "btop.theme"
$BtopLink = Join-Path $BtopThemesDir "current.theme"
New-Symlink -Target $BtopTheme -Link $BtopLink -Force

$BtopPersistedThemesDir = "$env:SCOOP\persist\btop\themes"
$BtopPersistedLink = Join-Path $BtopPersistedThemesDir "current.theme"
New-Symlink -Target $BtopTheme -Link $BtopPersistedLink -Force

# glazewm
$glazewmSettingsFile = Join-Path $env:HOME ".glzr\glazewm\config.yaml"
$glazewmSettingsContent = Get-Content $glazewmSettingsFile -Raw | ConvertFrom-Yaml
$glazewmThemeFile = Join-Path $CURRENT_THEME_DIR "glazewm.yaml"
$glazewmThemeContent = Get-Content $glazewmThemeFile -Raw | ConvertFrom-Yaml
$glazewmSettingsContent.window_effects.focused_window.border.color = $glazewmThemeContent.window_effects.focused_window.border.color
$glazewmSettingsContent.window_effects.other_windows.border.color = $glazewmThemeContent.window_effects.other_windows.border.color
$glazewmUpdatedSettingsContent = $glazewmSettingsContent | ConvertTo-Yaml
$glazewmUpdatedSettingsContent -replace "`r`n", "`n" | Set-Content $glazewmSettingsFile -NoNewline
glazewm command wm-reload-config

# k9s
$K9sSkinsDir = "$env:LOCALAPPDATA\k9s\skins"
if (-not (Test-Path $K9sSkinsDir)) {
  New-Item -ItemType Directory -Path $K9sSkinsDir | Out-Null
}
$K9sTheme = Join-Path $CURRENT_THEME_DIR "k9s.yaml"
$K9sLink = Join-Path $K9sSkinsDir "current.yaml"
New-Symlink -Target $K9sTheme -Link $K9sLink -Force

# lsd
$LsdColors = Join-Path $CURRENT_THEME_DIR "lsd.yaml"
$LsdLink = "$env:XDG_CONFIG_HOME\lsd\colors.yaml"
New-Symlink -Target $LsdColors -Link $LsdLink -Force

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
New-Symlink -Target $YaziTheme -Link $YaziLink -Force

$YaziFlavorsDir = Join-Path $CURRENT_THEME_DIR "yazi\flavors"
if (Test-Path $YaziFlavorsDir -PathType Container) {
  $YaziConfigFlavors = "$env:YAZI_CONFIG_HOME\flavors"
  if (-not (Test-Path $YaziConfigFlavors)) {
    New-Item -ItemType Directory -Path $YaziConfigFlavors | Out-Null
  }
  Get-ChildItem -Path $YaziFlavorsDir | ForEach-Object {
    $FlavorLink = Join-Path $YaziConfigFlavors $_.Name
    New-Symlink -Target $_.FullName -Link $FlavorLink -Force
  }
}

# Reload YASB to apply the new theme
yasbc reload

& "$PSScriptRoot\Set-BG.ps1" -BackgroundIndex 1

wsl -d NixOS -- zsh -c "set-theme '$THEME_NAME'"
