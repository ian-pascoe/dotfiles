<#
.SYNOPSIS
  The theme menu of YASB's theme widget: the Windows counterpart of the Hammerspoon theme menu on macOS.
.DESCRIPTION
  Shows a menu at the mouse pointer with the current theme (`family · variant · mode`), the light/dark mode (like
  Set-Mode.ps1), a random pick (like Random-Theme.ps1), a switch that sends theme picks to every machine
  (Set-Theme-All.ps1, Random-Theme-All.ps1), and every theme family with its dark and light palette strips (like
  List-Themes.ps1). A pick runs after the menu closes, and a notification reports how it went. One theme change runs at
  a time.
.PARAMETER ToggleMode
  Toggles the light/dark mode without the menu, as the Hammerspoon hotkey does.
#>
param([switch]$ToggleMode)

Import-Module Themes
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

Add-Type -Namespace ThemeMenu -Name Native -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);
[DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
[DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
'@

$allMachinesFile = Join-Path (Get-ThemeStateDir) "all-machines"

# Shows a notification and waits until it is gone; with -NoWait it returns its tray icon to dispose of later.
function Show-Notification([string]$Text, [int]$Seconds = 4, [switch]$NoWait) {
  $icon = [System.Windows.Forms.NotifyIcon]::new()
  $icon.Icon = [System.Drawing.SystemIcons]::Information
  $icon.Text = "Theme"
  $icon.Visible = $true
  $icon.ShowBalloonTip($Seconds * 1000, "Theme", $Text, [System.Windows.Forms.ToolTipIcon]::None)
  if ($NoWait) {
    return $icon
  }
  Start-Sleep -Seconds ($Seconds + 1)
  $icon.Dispose()
}

# Runs a theme script, and returns its exit code and output (which also has the errors it threw).
function Invoke-ThemeScript([string]$Script, [hashtable]$Arguments = @{}) {
  $global:LASTEXITCODE = 0
  try {
    $output = & (Join-Path $PSScriptRoot $Script) @Arguments *>&1 | Out-String
    $code = $LASTEXITCODE
  } catch {
    $output = "$_"
    $code = 1
  }
  [pscustomobject]@{ ExitCode = $code; Output = $output.Trim() }
}

function Set-ThemeMode([string]$Mode) {
  $result = Invoke-ThemeScript "Set-Mode.ps1" @{ Mode = $Mode }
  if ($result.ExitCode -ne 0) {
    Show-Notification "Mode change failed`n$($result.Output)"
    return
  }
  $saved = Get-SavedThemeMode
  Show-Notification ("Mode: {0}{1} ({2})" -f $saved.Substring(0, 1).ToUpper(), $saved.Substring(1), (Get-CurrentTheme).Name)
}

# Sets a family, or a random one when it is empty, here or on every machine. Set-Theme-All.ps1 prints a summary of
# which machines took it after a blank line.
function Set-ThemeFamily([string]$Family) {
  $allMachines = Test-Path -LiteralPath $allMachinesFile
  if (-not $Family) {
    $Family = Get-RandomThemeFamily -NoPreview
  }
  if ($allMachines) {
    $pending = Show-Notification "Setting $Family on all machines…" -NoWait
    $result = Invoke-ThemeScript "Set-Theme-All.ps1" @{ ThemeName = $Family }
    $pending.Dispose()
    $summary = ($result.Output -split "(?:\r?\n){2}")[-1]
    Show-Notification ($summary ? $summary : "Theme change failed")
  } else {
    $result = Invoke-ThemeScript "Set-Theme.ps1" @{ ThemeName = $Family }
    if ($result.ExitCode -eq 0) {
      Show-Notification "Theme: $(Format-ThemeLine (Get-CurrentTheme))"
    } else {
      Show-Notification "Theme change failed`n$($result.Output)"
    }
  }
}

# A palette strip as List-Themes.ps1 draws it: "Aa" in the foreground, then the six hues (palette 1-6), on the
# background. Sizes are at 96 DPI; Scale draws them for the screen.
$stripWidth, $stripHeight, $stripGap = 62, 14, 6

function Get-Color([string]$Hex) {
  [System.Drawing.ColorTranslator]::FromHtml($Hex)
}

function Add-RoundedRectangle([System.Drawing.Graphics]$Graphics, $Brush, [float]$X, [float]$Y, [float]$Width,
  [float]$Height, [float]$Radius) {
  $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
  $d = $Radius * 2
  $path.AddArc($X, $Y, $d, $d, 180, 90)
  $path.AddArc($X + $Width - $d, $Y, $d, $d, 270, 90)
  $path.AddArc($X + $Width - $d, $Y + $Height - $d, $d, $d, 0, 90)
  $path.AddArc($X, $Y + $Height - $d, $d, $d, 90, 90)
  $path.CloseFigure()
  $Graphics.FillPath($Brush, $path)
  $path.Dispose()
}

# The dark strip, then the light one, in fixed slots so family names line up; a family without a variant for a mode
# leaves that slot empty.
function New-FamilyImage($Family, [float]$Scale) {
  $bitmap = [System.Drawing.Bitmap]::new([int](($stripWidth * 2 + $stripGap) * $Scale), [int]($stripHeight * $Scale))
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
  $graphics.ScaleTransform($Scale, $Scale)
  $font = [System.Drawing.Font]::new("Consolas", 9, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
  $slot = 0
  foreach ($variant in $Family.Dark, $Family.Light) {
    $colors = if ($variant) { Get-ThemePalette $variant }
    if ($colors) {
      $x = $slot * ($stripWidth + $stripGap)
      $background = [System.Drawing.SolidBrush]::new((Get-Color $colors.Background))
      Add-RoundedRectangle $graphics $background $x 0 $stripWidth $stripHeight 3
      $foreground = [System.Drawing.SolidBrush]::new((Get-Color $colors.Foreground))
      $graphics.DrawString("Aa", $font, $foreground, $x + 2, 1)
      for ($i = 1; $i -le 6; $i++) {
        $hue = $colors.Palette[$i] ?? $colors.Foreground
        $brush = [System.Drawing.SolidBrush]::new((Get-Color $hue))
        Add-RoundedRectangle $graphics $brush ($x + 18 + ($i - 1) * 7) 3 6 8 1
        $brush.Dispose()
      }
      $background.Dispose()
      $foreground.Dispose()
    }
    $slot++
  }
  $font.Dispose()
  $graphics.Dispose()
  $bitmap
}

# Shows the menu and returns the picked item's Tag, or $null when it closed without a pick.
function Show-ThemeMenu {
  $pick = @{ Tag = $null }
  $current = Get-CurrentTheme
  $savedMode = Get-SavedThemeMode
  $allMachines = Test-Path -LiteralPath $allMachinesFile

  $screen = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
  $scale = $screen.DpiX / 96
  $screen.Dispose()

  $menu = [System.Windows.Forms.ContextMenuStrip]::new()
  $menu.ShowCheckMargin = $true
  $menu.ShowImageMargin = $true
  $menu.ImageScalingSize = [System.Drawing.Size]::new([int](($stripWidth * 2 + $stripGap) * $scale),
    [int]($stripHeight * $scale))

  $onClick = {
    param($item)
    $pick.Tag = $item.Tag
  }
  function Add-Item([string]$Text, $Tag, [bool]$Checked = $false, [bool]$Enabled = $true, $Image = $null) {
    $item = [System.Windows.Forms.ToolStripMenuItem]::new($Text)
    $item.Tag = $Tag
    $item.Checked = $Checked
    $item.Enabled = $Enabled
    if ($Image) {
      $item.Image = $Image
      $item.ImageScaling = [System.Windows.Forms.ToolStripItemImageScaling]::None
    }
    $item.Add_Click($onClick)
    $menu.Items.Add($item) | Out-Null
  }
  function Add-Separator {
    $menu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new()) | Out-Null
  }

  Add-Item ($current ? (Format-ThemeLine $current) : "No theme set") $null -Enabled $false
  Add-Separator
  Add-Item "Dark mode" @{ Kind = "mode"; Value = "dark" } -Checked ($savedMode -eq "dark")
  Add-Item "Light mode" @{ Kind = "mode"; Value = "light" } -Checked ($savedMode -eq "light")
  Add-Separator
  Add-Item "Random theme" @{ Kind = "family"; Value = "" }
  Add-Item "Apply to all machines" @{ Kind = "all-machines" } -Checked $allMachines
  Add-Separator
  foreach ($family in Get-ThemeFamily) {
    Add-Item $family.Name @{ Kind = "family"; Value = $family.Name } -Checked ($family.Name -eq $current.Family) `
      -Image (New-FamilyImage $family $scale)
  }

  # A menu only closes on a click elsewhere when its process has the foreground, which Windows keeps from a process
  # started in the background; a hidden window takes it by attaching to the foreground window's input first.
  $owner = [System.Windows.Forms.Form]::new()
  $owner.ShowInTaskbar = $false
  $owner.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
  $owner.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
  $owner.Location = [System.Windows.Forms.Cursor]::Position
  $owner.Size = [System.Drawing.Size]::new(1, 1)
  $owner.Opacity = 0
  $owner.TopMost = $true
  $owner.Add_Shown({
      $foregroundThread = [ThemeMenu.Native]::GetWindowThreadProcessId([ThemeMenu.Native]::GetForegroundWindow(), [IntPtr]::Zero)
      $thread = [ThemeMenu.Native]::GetCurrentThreadId()
      [ThemeMenu.Native]::AttachThreadInput($thread, $foregroundThread, $true) | Out-Null
      [ThemeMenu.Native]::SetForegroundWindow($owner.Handle) | Out-Null
      [ThemeMenu.Native]::AttachThreadInput($thread, $foregroundThread, $false) | Out-Null
      $menu.Show([System.Windows.Forms.Cursor]::Position)
    })
  $menu.Add_Closed({ $owner.Close() })
  [System.Windows.Forms.Application]::Run($owner)

  $menu.Dispose()
  $owner.Dispose()
  $pick.Tag
}

[System.Windows.Forms.Application]::EnableVisualStyles()
# Before any window: sharp text and strips on high-DPI screens, and the menu in the system's light or dark colors.
[System.Windows.Forms.Application]::SetHighDpiMode([System.Windows.Forms.HighDpiMode]::PerMonitorV2) | Out-Null
try {
  [System.Windows.Forms.Application]::SetColorMode([System.Windows.Forms.SystemColorMode]::System)
} catch {
  # Before .NET 9 menus are always light.
}

$busy = [System.Threading.Mutex]::new($false, "Local\ThemeMenu")
if (-not $busy.WaitOne(0)) {
  Show-Notification "A theme change is already running"
  exit 1
}
try {
  if ($ToggleMode) {
    Set-ThemeMode "toggle"
    exit 0
  }

  $tag = Show-ThemeMenu
  switch ($tag.Kind) {
    "mode" { Set-ThemeMode $tag.Value }
    "family" { Set-ThemeFamily $tag.Value }
    "all-machines" {
      if (Test-Path -LiteralPath $allMachinesFile) {
        Remove-Item -LiteralPath $allMachinesFile
      } else {
        New-Item -ItemType File -Force -Path $allMachinesFile | Out-Null
      }
    }
  }
} finally {
  $busy.ReleaseMutex()
  $busy.Dispose()
}
