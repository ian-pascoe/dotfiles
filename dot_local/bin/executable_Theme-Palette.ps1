<#
.SYNOPSIS
  Prints a theme variant's colors as truecolor swatches on its background, as theme-palette does.
.DESCRIPTION
  Reads the inline colors of the variant's ghostty.conf: the one file every variant has with a full terminal palette.
.PARAMETER Name
  The theme variant (folder name).
.PARAMETER Full
  Prints the normal (0-7) and bright (8-15) palette rows instead of one line with the foreground and the six hues.
#>
param(
  [Parameter(Mandatory = $true)]
  [ArgumentCompleter({
      param($commandName, $parameterName, $wordToComplete)
      Get-ThemeVariant | ForEach-Object Name | Where-Object { $_ -like "$wordToComplete*" }
    })]
  [string]$Name,

  [switch]$Full
)

Import-Module Themes

try {
  Format-ThemePalette $Name -Full:$Full
} catch {
  Write-Error $_
  exit 1
}
