param(
  [Parameter(Mandatory = $true)]
  [string]$ThemeName
)

$THEMES_DIR = "$env:USERPROFILE\.themes"
$CURRENT_THEME_DIR = "$env:USERPROFILE\.config\theme"

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

$StarshipTheme = Join-Path $CURRENT_THEME_DIR "starship.toml"
$StarshipConfig = "$env:USERPROFILE\.config\starship.toml"
if (Test-Path $StarshipTheme) {
  if (Test-Path $StarshipConfig) {
    Remove-Item $StarshipConfig -Force
  }
  New-Item -ItemType SymbolicLink -Path $StarshipConfig -Target $StarshipTheme | Out-Null
} else {
  $DefaultStarship = "$env:USERPROFILE\.dotfiles\config\starship.toml"
  if (Test-Path $StarshipConfig) {
    Remove-Item $StarshipConfig -Force
  }
  New-Item -ItemType SymbolicLink -Path $StarshipConfig -Target $DefaultStarship | Out-Null
}

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

$LsdColors = Join-Path $CURRENT_THEME_DIR "lsd.yaml"
$LsdLink = "$env:USERPROFILE\.config\lsd\colors.yaml"
if (Test-Path $LsdLink) {
  Remove-Item $LsdLink -Force
}
New-Item -ItemType SymbolicLink -Path $LsdLink -Target $LsdColors | Out-Null

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

$K9sSkinsDir = "$env:USERPROFILE\.config\k9s\skins"
if (-not (Test-Path $K9sSkinsDir)) {
  New-Item -ItemType Directory -Path $K9sSkinsDir | Out-Null
}
$K9sTheme = Join-Path $CURRENT_THEME_DIR "k9s.yaml"
$K9sLink = Join-Path $K9sSkinsDir "current.yaml"
if (Test-Path $K9sLink) {
  Remove-Item $K9sLink -Force
}
New-Item -ItemType SymbolicLink -Path $K9sLink -Target $K9sTheme | Out-Null

$YaziTheme = Join-Path $CURRENT_THEME_DIR "yazi\theme.toml"
$YaziLink = "$env:USERPROFILE\.config\yazi\theme.toml"
if (Test-Path $YaziLink) {
  Remove-Item $YaziLink -Force
}
New-Item -ItemType SymbolicLink -Path $YaziLink -Target $YaziTheme | Out-Null

$YaziFlavorsDir = Join-Path $CURRENT_THEME_DIR "yazi\flavors"
if (Test-Path $YaziFlavorsDir -PathType Container) {
  $YaziConfigFlavors = "$env:USERPROFILE\.config\yazi\flavors"
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

$FlowLauncherThemesDir = "$env:SCOOP\persist\flow-launcher\UserData\Themes"
if (-not (Test-Path $FlowLauncherThemesDir)) {
  New-Item -ItemType Directory -Path $FlowLauncherThemesDir | Out-Null
}
$FlowLauncherTheme = Join-Path $CURRENT_THEME_DIR "flow-launcher.xaml"
$FlowLauncherLink = Join-Path $FlowLauncherThemesDir "current.xaml"
if (Test-Path $FlowLauncherLink) {
  Remove-Item $FlowLauncherLink -Force
}
New-Item -ItemType HardLink -Path $FlowLauncherLink -Target $FlowLauncherTheme | Out-Null

yasbc reload

& "$PSScriptRoot\Set-BG.ps1" -BackgroundIndex 1
