<#
.SYNOPSIS
  Prints or changes the mode (light or dark) saved for this machine, as set-mode does.
.DESCRIPTION
  With no argument it prints the saved mode. Otherwise it saves the mode and switches the current theme family to its
  variant for that mode (see Set-Theme.ps1). A family with no variant for the mode keeps its current variant, and so
  does the Windows appearance: the theme decides it.
.PARAMETER Mode
  light, dark, or toggle.
#>
param(
  [ValidateSet("light", "dark", "toggle")]
  [string]$Mode
)

Import-Module (Join-Path $HOME Documents PowerShell Modules Themes) -ErrorAction Stop

$saved = Get-SavedThemeMode
if (-not $Mode) {
  $saved
  exit 0
}
if ($Mode -eq "toggle") {
  $Mode = if ($saved -eq "light") { "dark" } else { "light" }
}

Save-ThemeMode $Mode
"Mode: $Mode"

$current = Get-CurrentTheme
if (-not $current -or -not $current.Mode) {
  "No current theme to switch"
  exit 0
}

$variant = Resolve-Theme $current.Family $Mode
if ($variant.Mode -ne $Mode) {
  "$($current.Family) has no $Mode variant; staying on $($current.Name)"
} elseif ($variant.Name -ne $current.Name) {
  # The family name always resolves to that variant, whatever else is named alike.
  & "$PSScriptRoot\Set-Theme.ps1" -ThemeName $current.Family -Mode $Mode
  exit $LASTEXITCODE
}
