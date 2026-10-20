<#
.SYNOPSIS
  Lists theme families, one per line, as list-themes does.
.DESCRIPTION
  In a console each family also shows its variants as ☾ (dark) and ☀ (light) palette strips (see Theme-Palette.ps1),
  with * on the family of the current theme. Redirected output stays bare family names for scripts and completion.
#>

Import-Module Themes

$families = @(Get-ThemeFamily)
if ([Console]::IsOutputRedirected) {
  $families.Name
  exit 0
}

$width = ($families.Name | Measure-Object -Property Length -Maximum).Maximum
$current = (Get-CurrentTheme).Family
$variants = @(Get-ThemeVariant)
foreach ($family in $families) {
  $marker = if ($family.Name -eq $current) { '*' } else { ' ' }
  $strips = ''
  # Dark first, as theme-resolve --list orders them.
  foreach ($variant in $variants | Where-Object Family -EQ $family.Name) {
    $symbol = if ($variant.Mode -eq 'light') { '☀' } else { '☾' }
    $strip = try { Format-ThemePalette $variant.Name } catch { '' }
    $strips += " $symbol $strip"
  }
  "$marker $($family.Name.PadRight($width)) $strips"
}
