<#
.SYNOPSIS
  Sets the theme here and on every other machine on the tailnet, as set-theme-all does.
.DESCRIPTION
  Runs set-theme-all in the WSL distribution, which has the tools it needs (Tailscale, SSH, jq): it sets the theme in
  WSL, whose set-theme sets this Windows host in turn (see Set-Theme.ps1), and then on the other machines, and prints
  which machines took it. Without WSL only this machine changes.
  The mode (light or dark) goes along, defaulting to this machine's saved mode for a family and to the variant's own
  mode for a variant name; each machine applies set-theme's rules, so a family without that mode falls back there.
.PARAMETER ThemeName
  The theme family or variant to set.
.PARAMETER Mode
  light or dark.
.PARAMETER DryRun
  Checks each machine without changing anything.
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

  [Alias("n")]
  [switch]$DryRun
)

Import-Module (Join-Path $HOME Documents PowerShell Modules Themes) -ErrorAction Stop

# Resolve-Theme reports unknown names.
try {
  $variant = Resolve-Theme $ThemeName ($Mode ? $Mode : (Get-SavedThemeMode))
} catch {
  Write-Error $_
  exit 1
}
if (-not $Mode) {
  $Mode = if (Test-ThemeFamily $ThemeName) { Get-SavedThemeMode } else { $variant.Mode }
}

if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
  Write-Warning "WSL is missing; setting the theme on this machine only."
  if ($DryRun) {
    "ready; would use $($variant.Name); current theme: $((Get-CurrentTheme).Name)"
    exit 0
  }
  & "$PSScriptRoot\Set-Theme.ps1" -ThemeName $ThemeName -Mode $Mode -SkipWsl
  exit $LASTEXITCODE
}

if ($DryRun) {
  "== this Windows host ($env:COMPUTERNAME)"
  "  ready; would use $($variant.Name); current theme: $((Get-CurrentTheme).Name)"
}
$arguments = @(if ($DryRun) { "--dry-run" }) + @($ThemeName, $Mode)
wsl -d (Get-ThemeWslDistro) --exec zsh -lc 'export PATH="$HOME/.local/bin:$PATH"; set-theme-all "$@"' zsh @arguments
exit $LASTEXITCODE
