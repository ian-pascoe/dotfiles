<#
.SYNOPSIS
  Prints the current theme variant, as get-theme does.
.DESCRIPTION
  Prints the current theme variant's folder name. In a console it prints `family · variant · mode` instead (the
  variant's own mode, plus the saved mode when that differs, as for a dark-only family in light mode), followed by its
  full palette (see Theme-Palette.ps1). Redirected output stays the bare variant name.
.PARAMETER Json
  Prints the family, variant, mode, saved mode and that line as ASCII JSON, for the YASB theme widget.
#>
param([switch]$Json)

Import-Module Themes

$theme = Get-CurrentTheme
if ($Json) {
  [ordered]@{
    family    = $theme.Family ?? ''
    variant   = $theme.Name ?? ''
    mode      = $theme.Mode ?? ''
    savedMode = Get-SavedThemeMode
    line      = if ($theme) { Format-ThemeLine $theme } else { 'No theme set' }
  } | ConvertTo-Json -Compress -EscapeHandling EscapeNonAscii
  exit 0
}
if (-not $theme) {
  Write-Error "No current theme: $(Get-CurrentThemeLink) is not a link"
  exit 1
}
if ([Console]::IsOutputRedirected) {
  $theme.Name
  exit 0
}

Format-ThemeLine $theme
Format-ThemePalette $theme.Name -Full
