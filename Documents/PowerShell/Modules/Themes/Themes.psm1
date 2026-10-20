<#
.SYNOPSIS
  The theme variants under ~/.themes, for the Windows theme scripts.
.DESCRIPTION
  The PowerShell counterpart of the theme-resolve and theme-palette scripts, with the same rules: a theme variant is a
  folder in ~/.themes (or $env:THEMES_DIR); its family is the name in its `family` file, or the folder name; it is
  light when it has a light.mode file. A family name wins over a folder name and picks the variant for the mode, or its
  only variant when it has none for that mode. The mode is saved per machine in ~/.local/state/theme/mode (or under
  $env:XDG_STATE_HOME), dark by default. The current theme is the variant that ~/.config/theme (or under
  $env:XDG_CONFIG_HOME) links to.
  Nothing here needs the PowerShell profile, so the scripts also run with -NoProfile, as YASB and WSL start them.
#>

function Get-ThemesDir {
  if ($env:THEMES_DIR) { $env:THEMES_DIR } else { Join-Path $HOME '.themes' }
}

function Get-ThemeConfigHome {
  if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
}

# The link to the current theme variant, which every themed app reads through.
function Get-CurrentThemeLink {
  Join-Path (Get-ThemeConfigHome) 'theme'
}

# Per-machine theme state: the saved mode and the theme menu's settings.
function Get-ThemeStateDir {
  $stateHome = if ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $HOME '.local\state' }
  Join-Path $stateHome 'theme'
}

<#
.SYNOPSIS
  Lists the theme variants as objects with Name, Family, Mode and Path, sorted by family, dark first, as
  theme-resolve --list sorts them.
#>
function Get-ThemeVariant {
  $dir = Get-ThemesDir
  if (-not (Test-Path -LiteralPath $dir -PathType Container)) {
    return
  }

  $variants = [System.Collections.Generic.List[object]]::new()
  foreach ($folder in Get-ChildItem -LiteralPath $dir -Directory) {
    $familyFile = Join-Path $folder.FullName 'family'
    $family = if (Test-Path -LiteralPath $familyFile) { "$(Get-Content -LiteralPath $familyFile -TotalCount 1)".Trim() }
    $variants.Add([pscustomobject]@{
        Name   = $folder.Name
        Family = if ($family) { $family } else { $folder.Name }
        Mode   = if (Test-Path -LiteralPath (Join-Path $folder.FullName 'light.mode')) { 'light' } else { 'dark' }
        Path   = $folder.FullName
      })
  }
  # Ordinal, like theme-resolve's LC_ALL=C sort.
  $variants.Sort([Comparison[object]] {
      param($a, $b)
      $order = [string]::CompareOrdinal($a.Family, $b.Family)
      if ($order -eq 0) { $order = [string]::CompareOrdinal($a.Mode, $b.Mode) }
      if ($order -eq 0) { $order = [string]::CompareOrdinal($a.Name, $b.Name) }
      $order
    })
  $variants
}

<#
.SYNOPSIS
  Lists the theme families as objects with Name, Dark and Light (variant names, or $null), sorted by name.
#>
function Get-ThemeFamily {
  $families = [ordered]@{}
  foreach ($variant in Get-ThemeVariant) {
    if (-not $families.Contains($variant.Family)) {
      $families[$variant.Family] = [pscustomobject]@{ Name = $variant.Family; Dark = $null; Light = $null }
    }
    $family = $families[$variant.Family]
    if ($variant.Mode -eq 'light') {
      if (-not $family.Light) { $family.Light = $variant.Name }
    } elseif (-not $family.Dark) {
      $family.Dark = $variant.Name
    }
  }
  $families.Values
}

function Test-ThemeFamily {
  param([Parameter(Mandatory)][string]$Name)
  [bool](Get-ThemeVariant | Where-Object Family -EQ $Name | Select-Object -First 1)
}

function Get-SavedThemeMode {
  $modeFile = Join-Path (Get-ThemeStateDir) 'mode'
  $mode = if (Test-Path -LiteralPath $modeFile) { "$(Get-Content -LiteralPath $modeFile -TotalCount 1)".Trim() }
  if ($mode -eq 'light') { 'light' } else { 'dark' }
}

function Save-ThemeMode {
  param([Parameter(Mandatory)][ValidateSet('light', 'dark')][string]$Mode)
  $stateDir = Get-ThemeStateDir
  New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
  [IO.File]::WriteAllText((Join-Path $stateDir 'mode'), "$Mode`n")
}

<#
.SYNOPSIS
  Resolves a theme family or variant name to its variant, as theme-resolve does; throws for an unknown name.
.PARAMETER Mode
  light or dark; defaults to the saved mode.
#>
function Resolve-Theme {
  param(
    [Parameter(Mandatory)][string]$Name,
    [ValidateSet('light', 'dark')][string]$Mode = (Get-SavedThemeMode)
  )
  $variants = @(Get-ThemeVariant)
  $members = @($variants | Where-Object Family -EQ $Name)
  if ($members) {
    $match = $members | Where-Object Mode -EQ $Mode | Select-Object -First 1
    if ($match) { return $match }
    return $members[0]
  }
  $match = $variants | Where-Object Name -EQ $Name | Select-Object -First 1
  if ($match) { return $match }
  throw "Unknown theme '$Name': not a family or variant in $(Get-ThemesDir)"
}

<#
.SYNOPSIS
  The current theme variant (what ~/.config/theme links to), or $null when there is none.
#>
function Get-CurrentTheme {
  $link = Get-Item -LiteralPath (Get-CurrentThemeLink) -Force -ErrorAction SilentlyContinue
  if (-not $link -or -not $link.LinkTarget) {
    return $null
  }
  $name = Split-Path -Leaf $link.LinkTarget.TrimEnd('\', '/')
  $variant = Get-ThemeVariant | Where-Object Name -EQ $name | Select-Object -First 1
  if ($variant) { $variant } else { [pscustomobject]@{ Name = $name; Family = $name; Mode = $null; Path = $link.LinkTarget } }
}

<#
.SYNOPSIS
  `family · variant · mode` as get-theme prints it, with the saved mode when that differs (a dark-only family in light
  mode).
#>
function Format-ThemeLine {
  param([Parameter(Mandatory)]$Variant)
  $line = '{0} · {1} · {2}' -f $Variant.Family, $Variant.Name, ($Variant.Mode ?? 'unknown')
  $saved = Get-SavedThemeMode
  if ($Variant.Mode -and $Variant.Mode -ne $saved) {
    $line += " (saved: $saved)"
  }
  $line
}

<#
.SYNOPSIS
  Points a link at a target, replacing what is there. A link is removed on its own, never what it points to.
#>
function Set-ThemeLink {
  param(
    [Parameter(Mandatory)][string]$Target,
    [Parameter(Mandatory)][string]$Link
  )
  $existing = Get-Item -LiteralPath $Link -Force -ErrorAction SilentlyContinue
  if ($existing) {
    if ($existing.LinkType) {
      $existing.Delete()
    } else {
      Remove-Item -LiteralPath $Link -Recurse -Force
    }
  }
  New-Item -ItemType SymbolicLink -Path $Link -Value $Target | Out-Null
}

<#
.SYNOPSIS
  A variant's background, foreground and palette 0-15 (as #rrggbb), read from its ghostty.conf: the one file every
  variant has with a full terminal palette. $null when it has none.
#>
function Get-ThemePalette {
  param([Parameter(Mandatory)][string]$Name)
  $conf = Join-Path (Join-Path (Get-ThemesDir) $Name) 'ghostty.conf'
  if (-not (Test-Path -LiteralPath $conf)) {
    return $null
  }

  $colors = @{ Background = $null; Foreground = $null; Palette = [string[]]::new(16) }
  foreach ($line in Get-Content -LiteralPath $conf) {
    $line = $line -replace '[\s#]', ''
    if ($line -match '^(background|foreground)=([0-9a-fA-F]{6})$') {
      $colors[$Matches[1]] = "#$($Matches[2])"
    } elseif ($line -match '^palette=(\d+)=([0-9a-fA-F]{6})$' -and [int]$Matches[1] -lt 16) {
      $colors.Palette[[int]$Matches[1]] = "#$($Matches[2])"
    }
  }
  if (-not ($colors.Background -and $colors.Foreground)) {
    return $null
  }
  [pscustomobject]$colors
}

<#
.SYNOPSIS
  A variant's colors as truecolor swatches on its background, as theme-palette draws them: one line with the
  foreground and the six hues (palette 1-6), or with -Full the normal (0-7) and bright (8-15) rows.
#>
function Format-ThemePalette {
  param(
    [Parameter(Mandatory)][string]$Name,
    [switch]$Full
  )
  $colors = Get-ThemePalette $Name
  if (-not $colors) {
    throw "Theme '$Name' has no $(Join-Path (Join-Path (Get-ThemesDir) $Name) 'ghostty.conf')"
  }

  function rgb([string]$hex) {
    if (-not $hex) { $hex = '#000000' }
    '{0};{1};{2}' -f [Convert]::ToInt32($hex.Substring(1, 2), 16), [Convert]::ToInt32($hex.Substring(3, 2), 16),
    [Convert]::ToInt32($hex.Substring(5, 2), 16)
  }
  function strip([string]$lead, [int[]]$indexes) {
    $out = "`e[48;2;$(rgb $colors.Background)m`e[38;2;$(rgb $colors.Foreground)m$lead"
    foreach ($i in $indexes) {
      $out += "`e[38;2;$(rgb $colors.Palette[$i])m██"
    }
    "$out `e[0m"
  }

  if ($Full) {
    strip ' Aa ' (0..7)
    strip '    ' (8..15)
  } else {
    strip ' Aa ' (1..6)
  }
}

<#
.SYNOPSIS
  Picks a random theme family and returns its name, as roll-theme does. In an interactive console it first previews
  each roll (the variant for the saved mode and its full palette) and asks to apply it, reroll or quit; quitting
  returns $null.
.PARAMETER NoPreview
  Returns the first roll without asking, as when there is no console.
#>
function Get-RandomThemeFamily {
  param([switch]$NoPreview)
  $families = @(Get-ThemeFamily | ForEach-Object Name)
  if (-not $families) {
    throw "No themes found in $(Get-ThemesDir)"
  }
  if ($NoPreview -or [Console]::IsInputRedirected -or [Console]::IsOutputRedirected -or
    -not [Environment]::UserInteractive) {
    return Get-Random -InputObject $families
  }

  $theme = $null
  while ($true) {
    # A reroll never repeats the theme just shown.
    $previous = $theme
    do {
      $theme = Get-Random -InputObject $families
    } while ($families.Count -gt 1 -and $theme -eq $previous)

    $variant = Resolve-Theme $theme
    Write-Host ''
    Write-Host "$theme · $($variant.Name) · $($variant.Mode)"
    Format-ThemePalette $variant.Name -Full | Write-Host
    Write-Host 'Apply? [Y]es / [r]eroll / [q]uit ' -NoNewline
    $key = [Console]::ReadKey($true)
    Write-Host ''
    switch -Regex ($key.KeyChar) {
      '^[yY\r\n]$' { return $theme }
      '^[rR]$' { continue }
      default {
        Write-Host 'Cancelled'
        return $null
      }
    }
  }
}

# The WSL distribution that follows this machine's theme (it runs the Linux theme scripts).
function Get-ThemeWslDistro {
  if ($env:WSL_NIXOS_DISTRO) { $env:WSL_NIXOS_DISTRO } else { 'NixOS' }
}

Export-ModuleMember -Function Get-ThemesDir, Get-ThemeConfigHome, Get-CurrentThemeLink, Get-ThemeStateDir,
Get-ThemeVariant, Get-ThemeFamily, Test-ThemeFamily, Get-SavedThemeMode, Save-ThemeMode, Resolve-Theme,
Get-CurrentTheme, Format-ThemeLine, Set-ThemeLink, Get-ThemePalette, Format-ThemePalette, Get-RandomThemeFamily,
Get-ThemeWslDistro
