<#
.SYNOPSIS
  Sets a random theme family on every machine, in this machine's saved mode, as random-theme-all does.
.DESCRIPTION
  See Set-Theme-All.ps1. In a console it previews the roll and asks to apply or reroll first.
.PARAMETER DryRun
  Checks each machine without changing anything.
#>
param([Alias("n")][switch]$DryRun)

Import-Module (Join-Path $HOME Documents PowerShell Modules Themes) -ErrorAction Stop

$theme = Get-RandomThemeFamily
if (-not $theme) {
  exit 1
}
& "$PSScriptRoot\Set-Theme-All.ps1" -ThemeName $theme -DryRun:$DryRun
exit $LASTEXITCODE
