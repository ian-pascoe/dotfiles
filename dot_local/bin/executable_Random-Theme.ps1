<#
.SYNOPSIS
  Sets a random theme family in the saved mode, as random-theme does.
.DESCRIPTION
  In a console it previews each roll and asks to apply it, reroll or quit first (see Get-RandomThemeFamily in the
  Themes module).
#>

Import-Module Themes

$theme = Get-RandomThemeFamily
if (-not $theme) {
  exit 1
}
& "$PSScriptRoot\Set-Theme.ps1" -ThemeName $theme
exit $LASTEXITCODE
