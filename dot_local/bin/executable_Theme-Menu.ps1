<#
.SYNOPSIS
  The theme menu of YASB's theme widget: the Windows counterpart of the Hammerspoon theme menu on macOS.
.DESCRIPTION
  Shows a menu at the mouse pointer with the current theme (`family · variant · mode`), the light/dark mode (like
  Set-Mode.ps1), a random pick (like Random-Theme.ps1), a switch that sends theme picks to every machine
  (Set-Theme-All.ps1, Random-Theme-All.ps1), and every theme family with its dark and light palette strips (like
  List-Themes.ps1). A pick runs after the menu closes, and a notification reports how it went. Requests wait while a
  theme change runs.
  The menu keeps running after its first request, so later ones open it at once: Theme-Menu.cmd, which YASB runs,
  hands a request to it through the \\.\pipe\ThemeMenu pipe and starts this script when nothing listens there. Started
  while the menu runs, this script passes its request on the same way. The running menu restarts itself on its next
  request after this script or the Themes module changes.
.PARAMETER Request
  menu (the default) opens the menu, or closes it when it is open; toggle-mode toggles the light/dark mode, as the
  Hammerspoon hotkey does; quit stops the running menu.
.PARAMETER ToggleMode
  The same as -Request toggle-mode.
#>
param(
  [ValidateSet("menu", "toggle-mode", "quit")]
  [string]$Request = "menu",
  [switch]$ToggleMode
)

if ($ToggleMode) {
  $Request = "toggle-mode"
}
$pipeName = "ThemeMenu"

# Hands a request to the running menu; false when none takes it within the timeout.
function Send-MenuRequest([string]$Request, [int]$TimeoutMs) {
  $client = [System.IO.Pipes.NamedPipeClientStream]::new(".", $pipeName, [System.IO.Pipes.PipeDirection]::Out)
  try {
    $client.Connect($TimeoutMs)
    $bytes = [System.Text.Encoding]::ASCII.GetBytes("$Request`r`n")
    $client.Write($bytes, 0, $bytes.Length)
    $client.Flush()
    $true
  } catch {
    $false
  } finally {
    $client.Dispose()
  }
}

if (Send-MenuRequest $Request 100) {
  exit 0
}
if ($Request -eq "quit") {
  exit 0
}

# Nothing listens, so this becomes the menu, unless another one is starting up: that one takes the request once it
# listens.
try {
  $running = [System.Threading.Mutex]::new($false, "Local\ThemeMenu")
  $owned = $running.WaitOne(0)
} catch [System.Threading.AbandonedMutexException] {
  $owned = $true
} catch {
  $owned = $false
}
if (-not $owned) {
  exit $(if (Send-MenuRequest $Request 15000) { 0 } else { 1 })
}

Import-Module (Join-Path $HOME Documents PowerShell Modules Themes) -ErrorAction Stop
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()
# Before any window: sharp text and strips on high-DPI screens, and the menu in the system's light or dark colors.
[System.Windows.Forms.Application]::SetHighDpiMode([System.Windows.Forms.HighDpiMode]::PerMonitorV2) | Out-Null
try {
  [System.Windows.Forms.Application]::SetColorMode([System.Windows.Forms.SystemColorMode]::System)
} catch {
  # Before .NET 9 menus are always light.
}

Add-Type -Namespace ThemeMenu -Name Native -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
[DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, IntPtr processId);
[DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
[DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
[DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
'@

$allMachinesFile = Join-Path (Get-ThemeStateDir) "all-machines"

# What the event handlers share; they change its entries, as a variable they set would be their own.
$state = @{
  # Requests from the pipe, in order.
  Requests    = [System.Collections.Generic.Queue[string]]::new()
  Server      = $null
  Connection  = $null
  # The menu, built once and again when the themes or the screen scale change (Key).
  Menu        = $null
  Key         = $null
  Items       = @{}
  Families    = [System.Collections.Generic.List[object]]::new()
  Images      = [System.Collections.Generic.List[object]]::new()
  Open        = $false
  # The picked item's Tag, run once the menu has closed.
  Pick        = $null
  # When the menu last closed without a pick: a click on the widget closes the menu before its request comes in.
  DismissedAt = [datetime]::MinValue
  Notices     = [System.Collections.Generic.List[object]]::new()
  Stopped     = $false
}

# This script and the module as they were at the start; a change restarts the menu.
function Get-CodeStamp {
  ($PSCommandPath, (Get-Module Themes).Path | ForEach-Object { [System.IO.File]::GetLastWriteTimeUtc($_).Ticks }) -join "|"
}
$codeStamp = Get-CodeStamp

# Shows a notification for some seconds, and returns its tray icon for an earlier Dispose.
function Show-Notification([string]$Text, [int]$Seconds = 4) {
  if ($Text.Length -gt 250) {
    $Text = $Text.Substring(0, 249) + "…"
  }
  $icon = [System.Windows.Forms.NotifyIcon]::new()
  $icon.Icon = [System.Drawing.SystemIcons]::Information
  $icon.Text = "Theme"
  $icon.Visible = $true
  $icon.ShowBalloonTip($Seconds * 1000, "Theme", $Text, [System.Windows.Forms.ToolTipIcon]::None)
  $state.Notices.Add([pscustomobject]@{ Icon = $icon; Until = [datetime]::UtcNow.AddSeconds($Seconds + 1) })
  $icon
}

function Remove-ExpiredNotification {
  for ($i = $state.Notices.Count - 1; $i -ge 0; $i--) {
    if ($state.Notices[$i].Until -lt [datetime]::UtcNow) {
      $state.Notices[$i].Icon.Dispose()
      $state.Notices.RemoveAt($i)
    }
  }
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
    Show-Notification "Mode change failed`n$($result.Output)" | Out-Null
    return
  }
  $saved = Get-SavedThemeMode
  Show-Notification ("Mode: {0}{1} ({2})" -f $saved.Substring(0, 1).ToUpper(), $saved.Substring(1),
    (Get-CurrentTheme).Name) | Out-Null
}

# Sets a family, or a random one when it is empty, here or on every machine. Set-Theme-All.ps1 prints a summary of
# which machines took it after a blank line.
function Set-ThemeFamily([string]$Family) {
  $allMachines = Test-Path -LiteralPath $allMachinesFile
  if (-not $Family) {
    $Family = Get-RandomThemeFamily -NoPreview
  }
  if ($allMachines) {
    $pending = Show-Notification "Setting $Family on all machines…" 600
    $result = Invoke-ThemeScript "Set-Theme-All.ps1" @{ ThemeName = $Family }
    $pending.Dispose()
    $summary = ($result.Output -split "(?:\r?\n){2}")[-1]
    Show-Notification ($summary ? $summary : "Theme change failed") | Out-Null
  } else {
    $result = Invoke-ThemeScript "Set-Theme.ps1" @{ ThemeName = $Family }
    if ($result.ExitCode -eq 0) {
      Show-Notification "Theme: $(Format-ThemeLine (Get-CurrentTheme))" | Out-Null
    } else {
      Show-Notification "Theme change failed`n$($result.Output)" | Out-Null
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

# Builds the menu's items; Show-ThemeMenu sets their text and checks each time.
function New-ThemeMenu([float]$Scale) {
  $menu = [System.Windows.Forms.ContextMenuStrip]::new()
  $menu.ShowCheckMargin = $true
  $menu.ShowImageMargin = $true
  $menu.ImageScalingSize = [System.Drawing.Size]::new([int](($stripWidth * 2 + $stripGap) * $Scale),
    [int]($stripHeight * $Scale))

  function Add-Item([string]$Text, $Tag, [bool]$Enabled = $true, $Image = $null) {
    $item = [System.Windows.Forms.ToolStripMenuItem]::new($Text)
    $item.Tag = $Tag
    $item.Enabled = $Enabled
    if ($Image) {
      $item.Image = $Image
      $item.ImageScaling = [System.Windows.Forms.ToolStripItemImageScaling]::None
    }
    $item.Add_Click({
        param($item)
        $state.Pick = $item.Tag
      })
    $menu.Items.Add($item) | Out-Null
    $item
  }
  function Add-Separator {
    $menu.Items.Add([System.Windows.Forms.ToolStripSeparator]::new()) | Out-Null
  }

  $state.Items = @{}
  $state.Families.Clear()
  $state.Items.Header = Add-Item "" $null -Enabled $false
  Add-Separator
  $state.Items.Dark = Add-Item "Dark mode" @{ Kind = "mode"; Value = "dark" }
  $state.Items.Light = Add-Item "Light mode" @{ Kind = "mode"; Value = "light" }
  Add-Separator
  Add-Item "Random theme" @{ Kind = "family"; Value = "" } | Out-Null
  $state.Items.AllMachines = Add-Item "Apply to all machines" @{ Kind = "all-machines" }
  Add-Separator
  foreach ($family in Get-ThemeFamily) {
    $image = New-FamilyImage $family $Scale
    $state.Images.Add($image)
    $state.Families.Add((Add-Item $family.Name @{ Kind = "family"; Value = $family.Name } -Image $image))
  }

  $menu.Add_Closed({
      param($menu, $closing)
      $state.Open = $false
      if ($closing.CloseReason -ne [System.Windows.Forms.ToolStripDropDownCloseReason]::ItemClicked) {
        $state.DismissedAt = [datetime]::UtcNow
      }
      $owner.Hide()
    })
  $menu
}

# A menu only closes on a click elsewhere when its process has the foreground, which Windows keeps from a process in
# the background; this hidden window takes it by attaching to the foreground window's input first.
$owner = [System.Windows.Forms.Form]::new()
$owner.ShowInTaskbar = $false
$owner.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$owner.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
$owner.Size = [System.Drawing.Size]::new(1, 1)
$owner.Opacity = 0
$owner.TopMost = $true

function Show-ThemeMenu {
  $screen = [System.Drawing.Graphics]::FromHwnd([IntPtr]::Zero)
  $scale = $screen.DpiX / 96
  $screen.Dispose()
  # A theme folder added or removed changes the folder's write time.
  $key = "$scale|$([System.IO.Directory]::GetLastWriteTimeUtc((Get-ThemesDir)).Ticks)"
  if ($state.Key -ne $key) {
    if ($state.Menu) {
      $state.Menu.Dispose()
      $state.Images | ForEach-Object Dispose
      $state.Images.Clear()
    }
    $state.Menu = New-ThemeMenu $scale
    $state.Key = $key
  }

  $current = Get-CurrentTheme
  $savedMode = Get-SavedThemeMode
  $state.Items.Header.Text = if ($current) { Format-ThemeLine $current } else { "No theme set" }
  $state.Items.Dark.Checked = $savedMode -eq "dark"
  $state.Items.Light.Checked = $savedMode -eq "light"
  $state.Items.AllMachines.Checked = Test-Path -LiteralPath $allMachinesFile
  foreach ($item in $state.Families) {
    $item.Checked = $current -and $item.Tag.Value -eq $current.Family
  }

  $owner.Location = [System.Windows.Forms.Cursor]::Position
  $owner.Show()
  $foregroundThread = [ThemeMenu.Native]::GetWindowThreadProcessId([ThemeMenu.Native]::GetForegroundWindow(), [IntPtr]::Zero)
  $thread = [ThemeMenu.Native]::GetCurrentThreadId()
  [ThemeMenu.Native]::AttachThreadInput($thread, $foregroundThread, $true) | Out-Null
  [ThemeMenu.Native]::SetForegroundWindow($owner.Handle) | Out-Null
  [ThemeMenu.Native]::AttachThreadInput($thread, $foregroundThread, $false) | Out-Null
  $state.Pick = $null
  $state.Open = $true
  $state.Menu.Show([System.Windows.Forms.Cursor]::Position)
}

function Invoke-Pick($Tag) {
  switch ($Tag.Kind) {
    "mode" { Set-ThemeMode $Tag.Value }
    "family" { Set-ThemeFamily $Tag.Value }
    "all-machines" {
      if (Test-Path -LiteralPath $allMachinesFile) {
        Remove-Item -LiteralPath $allMachinesFile
      } else {
        New-Item -ItemType File -Force -Path $allMachinesFile | Out-Null
      }
    }
  }
}

function Start-Listening {
  if ($state.Server) {
    $state.Server.Dispose()
  }
  $state.Server = [System.IO.Pipes.NamedPipeServerStream]::new($pipeName, [System.IO.Pipes.PipeDirection]::In, 1,
    [System.IO.Pipes.PipeTransmissionMode]::Byte, [System.IO.Pipes.PipeOptions]::Asynchronous)
  $state.Connection = $state.Server.WaitForConnectionAsync()
}

# Queues the request of a client that has connected, and listens for the next one. Theme-Menu.cmd writes a line and
# disconnects.
function Receive-MenuRequest {
  if (-not $state.Connection.IsCompleted) {
    return
  }
  if (-not $state.Connection.IsCompletedSuccessfully) {
    Start-Listening
    return
  }
  try {
    $reader = [System.IO.StreamReader]::new($state.Server, [System.Text.Encoding]::ASCII, $false, 256, $true)
    $line = $reader.ReadLine()
    $reader.Dispose()
    if ($line -and $line.Trim()) {
      $state.Requests.Enqueue($line.Trim())
    }
    $state.Server.Disconnect()
    $state.Connection = $state.Server.WaitForConnectionAsync()
  } catch {
    Start-Listening
  }
}

function Stop-Menu {
  $state.Stopped = $true
  $state.Server.Dispose()
  $state.Notices | ForEach-Object { $_.Icon.Dispose() }
  $running.ReleaseMutex()
  [System.Windows.Forms.Application]::ExitThread()
}

# Handles what has come in: an open menu closes for any request (a second click on the widget only closes it),
# a pick runs once the menu has closed, and then requests run in order.
function Invoke-Tick {
  Remove-ExpiredNotification
  Receive-MenuRequest
  if ($state.Open) {
    if ($state.Requests.Count) {
      $state.Menu.Close()
      if ($state.Requests.Peek() -eq "menu") {
        $state.Requests.Dequeue() | Out-Null
      }
    }
    return
  }
  if ($state.Pick) {
    $tag = $state.Pick
    $state.Pick = $null
    Invoke-Pick $tag
    return
  }
  if (-not $state.Requests.Count) {
    return
  }

  $request = $state.Requests.Dequeue()
  if ($request -ne "quit" -and (Get-CodeStamp) -ne $codeStamp) {
    # Changed code takes over: a new menu process starts with this request.
    Stop-Menu
    Start-Process pwsh -WindowStyle Hidden -ArgumentList "-NoProfile", "-NonInteractive", "-File",
    "`"$PSCommandPath`"", "-Request", $request
    return
  }
  switch ($request) {
    "menu" {
      if (([datetime]::UtcNow - $state.DismissedAt).TotalMilliseconds -gt 600) {
        Show-ThemeMenu
      }
    }
    "toggle-mode" { Set-ThemeMode "toggle" }
    "quit" { Stop-Menu }
  }
}

Start-Listening
$state.Requests.Enqueue($Request)
$timer = [System.Windows.Forms.Timer]::new()
$timer.Interval = 50
$timer.Add_Tick({
    # A theme change takes seconds; ticks wait for it.
    $timer.Stop()
    try {
      Invoke-Tick
    } catch {
      Show-Notification "Theme menu error`n$_" | Out-Null
    } finally {
      if (-not $state.Stopped) {
        $timer.Start()
      }
    }
  })
$timer.Start()
[System.Windows.Forms.Application]::Run([System.Windows.Forms.ApplicationContext]::new())
