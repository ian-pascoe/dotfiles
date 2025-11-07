# Import Modules and External Profiles
Import-Module PSReadLine -ErrorAction SilentlyContinue
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module PowerShell-Yaml -ErrorAction SilentlyContinue
Import-Module gsudoModule -ErrorAction SilentlyContinue

function Test-Command {
  param (
    [string]$commandName
  )
  return Get-Command $commandName -ErrorAction SilentlyContinue
}

function Write-Log {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Message,
    [ValidateSet("Info", "Success", "Warning", "Error")]
    [string]$Level = "Info"
  )
  
  $color = switch ($Level) {
    "Info" {
      "Cyan" 
    }
    "Success" {
      "Green" 
    }
    "Warning" {
      "Yellow" 
    }
    "Error" {
      "Red" 
    }
  }
  
  $prefix = switch ($Level) {
    "Info" {
      "[INFO]" 
    }
    "Success" {
      "[SUCCESS]" 
    }
    "Warning" {
      "[WARNING]" 
    }
    "Error" {
      "[ERROR]" 
    }
  }
  
  Write-Host "$prefix $Message" -ForegroundColor $color
}

function Invoke-WithErrorHandling {
  param(
    [Parameter(Mandatory = $true)]
    [scriptblock]$ScriptBlock,
    [Parameter(Mandatory = $true)]
    [string]$ErrorMessage,
    [switch]$ContinueOnError = $false
  )
  
  try {
    & $ScriptBlock
    return $true
  } catch {
    Write-Log -Message "$ErrorMessage : $_" -Level Error
    if (-not $ContinueOnError) {
      throw
    }
    return $false
  }
}

function Test-PathInEnvironmentVariable {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$VariableName
  )
  
  $currentValue = [Environment]::GetEnvironmentVariable($VariableName, 'User')
  if (-not $currentValue) {
    $currentValue = [Environment]::GetEnvironmentVariable($VariableName, 'Machine')
  }
  if (-not $currentValue) {
    $currentValue = [Environment]::GetEnvironmentVariable($VariableName, 'Process')
  }
  
  if (-not $currentValue) {
    return $false
  }
  
  # Normalize paths for comparison
  $normalizedPath = $Path.TrimEnd('\', '/').Replace('/', '\')
  $paths = $currentValue -split ';' | ForEach-Object { 
    $_.TrimEnd('\', '/').Replace('/', '\') 
  }
  
  return $paths -contains $normalizedPath
}

function Add-ToEnvironmentVariable {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Path,
    [Parameter(Mandatory = $true)]
    [string]$VariableName,
    [switch]$Prepend = $false,
    [ValidateSet("Process", "User", "Machine")]
    [string]$Level = 'User'
  )
  
  if (Test-PathInEnvironmentVariable -Path $Path -VariableName $VariableName) {
    Write-Log -Message "$Path already in $VariableName" -Level Info
    return $false
  }
  
  $currentValue = [Environment]::GetEnvironmentVariable($VariableName, $Level)
  if (-not $currentValue) {
    $currentValue = ""
  }
  
  $newValue = if ($Prepend) {
    if ($currentValue) {
      "$Path;$currentValue" 
    } else {
      $Path 
    }
  } else {
    if ($currentValue) {
      "$currentValue;$Path" 
    } else {
      $Path 
    }
  }
  
  Set-Item -Force -Path "env:$VariableName" -Value $newValue
  [Environment]::SetEnvironmentVariable($VariableName, $newValue, $Level)
  Write-Log -Message "Added $Path to $VariableName" -Level Success
  return $true
}

function Test-ScheduledTaskNeedsUpdate {
  param(
    [Parameter(Mandatory = $true)]
    [string]$TaskName,
    [Parameter(Mandatory = $true)]
    [string]$ExecutablePath,
    [string]$Arguments = ""
  )
  
  $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
  if (-not $task) {
    return $true
  }
  
  $action = $task.Actions | Select-Object -First 1
  if (-not $action) {
    return $true
  }
  
  # Normalize paths for comparison
  $currentExe = $action.Execute.TrimEnd('\', '/').Replace('/', '\')
  $newExe = $ExecutablePath.TrimEnd('\', '/').Replace('/', '\')
  
  if ($currentExe -ne $newExe) {
    return $true
  }
  
  if ($action.Arguments -ne $Arguments) {
    return $true
  }
  
  return $false
}

function Update-PowerShell {
  Invoke-WithErrorHandling -ErrorMessage "Failed to update Powershell" -ScriptBlock {
    Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
    $updateNeeded = $false
    $currentVersion = $PSVersionTable.PSVersion.ToString()
    $gitHubApiUrl = "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
    $latestReleaseInfo = Invoke-RestMethod -Uri $gitHubApiUrl
    $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
    if ($currentVersion -lt $latestVersion) {
      $updateNeeded = $true
    }

    if ($updateNeeded) {
      Write-Host "Updating PowerShell..." -ForegroundColor Yellow
      Start-Process powershell.exe -ArgumentList "-NoProfile -Command winget upgrade Microsoft.PowerShell --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
      Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
    } else {
      Write-Host "Your PowerShell is up to date." -ForegroundColor Green
    }
  }
}

# starship init
if (Test-Command -commandName "starship") {
  Invoke-Expression (& { (starship init powershell --print-full-init | Out-String) })
}

# zoxide
if (Test-Command -commandName "zoxide") {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
  Set-Alias -Name cd -Value z -Option AllScope
}

# lsd
if (Test-Command -commandName "lsd") {
  Set-Alias -Name ls -Value lsd -Option AllScope
  function ll {
    lsd -l $args
  }
  function lla {
    lsd -lA $args
  }
}

# bat
if (Test-Command -commandName "bat") {
  function Get-FileList {
    bat --paging=never $args
  }
  Set-Alias -Name cat -Value Get-FileList -Option AllScope
}

# fd-find
if (Test-Command -commandName "fd") {
  Set-Alias -Name find -Value fd -Option AllScope
}

# ripgrep
if (Test-Command -commandName "rg") {
  Set-Alias -Name grep -Value rg -Option AllScope
}

if (Test-Command -commandName "yazi") {
  function y {
    $tmp = (New-TemporaryFile).FullName
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
      Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -Path $tmp
  }
}

## Utility functions

# File System Utilities
function touch($file) {
  "" | Out-File -FilePath $file -Encoding ASCII
}

function New-Link {
  param(
    [string]$Target,
    [string]$Link,
    [switch]$Force = $false,
    [ValidateSet("HardLink", "SymbolicLink")]
    [string]$LinkType = "HardLink"
  )
  if ($Force -and (Test-Path $Link)) {
    Remove-Item $Link -Recurse -Force
  }
  New-Item -Path $Link -ItemType $LinkType -Value $Target
}
function New-Symlink {
  param(
    [string]$Target,
    [string]$Link,
    [switch]$Force = $false
  )
  New-Link -Target $Target -Link $Link -LinkType SymbolicLink -Force:$Force
}
function ln($target, $link, [switch]$f, [switch]$s=$false) {
  if ($s) {
    New-Link -Target $target -Link $link -LinkType SymbolicLink -Force:$f
  } else {
    New-Link -Target $target -Link $link -LinkType HardLink -Force:$f
  }
}

function rm($path, [switch]$r=$false, [switch]$f=$false) {
  Remove-Item -Path $path -Recurse:$r -Force:$f
}

function df {
  Get-Volume
}

function unzip($file) {
  Write-Output("Extracting", $file, "to", $pwd)
  $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
  Expand-Archive -Path $fullFile -DestinationPath $pwd
}

function trash($path) {
  $fullPath = (Resolve-Path -Path $path).Path

  if (Test-Path $fullPath) {
    $item = Get-Item $fullPath

    if ($item.PSIsContainer) {
      # Handle directory
      $parentPath = $item.Parent.FullName
    } else {
      # Handle file
      $parentPath = $item.DirectoryName
    }

    $shell = New-Object -ComObject 'Shell.Application'
    $shellItem = $shell.NameSpace($parentPath).ParseName($item.Name)

    if ($item) {
      $shellItem.InvokeVerb('delete')
      Write-Host "Item '$fullPath' has been moved to the Recycle Bin."
    } else {
      Write-Host "Error: Could not find the item '$fullPath' to trash."
    }
  } else {
    Write-Host "Error: Item '$fullPath' does not exist."
  }
}

function Get-WSLPath($windowsPath) {
  $escapedPath = $windowsPath.Replace('\', '\\')
  $wslPath = wsl -d NixOS -- wslpath -a "$escapedPath"
  return $wslPath
}

# Network Utilities
function Get-PubIP {
  (Invoke-WebRequest http://ifconfig.me/ip).Content 
}

function flushdns {
  Clear-DnsClientCache
  Write-Host "DNS has been flushed"
}

# Environment Utilities
function Set-EnvironmentVariable() {
  param(
    [string]$Name,
    [string]$Value,
    [switch]$Persist=$false,
    [ValidateSet("Process", "User", "Machine")]
    [string]$Level = 'User'
  )
  Set-Item -force -path "env:$Name" -value $Value;
  if ($Persist) {
    [Environment]::SetEnvironmentVariable($Name, $Value, $Level)
  }
}

function export($name, $value, [switch]$p=$false) {
  Set-EnvironmentVariable -Name $name -Value $value -Persist:$p
}

function which($name) {
  Get-Command $name | Select-Object -ExpandProperty Definition
}

function pkill($name) {
  Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
}

function pgrep($name) {
  Get-Process $name
}

function head {
  param($Path, $n = 10)
  Get-Content $Path -Head $n
}

function tail {
  param($Path, $n = 10, [switch]$f = $false)
  Get-Content $Path -Tail $n -Wait:$f
}

function sysinfo {
  Get-ComputerInfo
}

function Clear-Cache {
  Write-Host "Clearing cache..." -ForegroundColor Cyan

  # Clear Windows Prefetch
  Write-Host "Clearing Windows Prefetch..." -ForegroundColor Yellow
  Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

  # Clear Windows Temp
  Write-Host "Clearing Windows Temp..." -ForegroundColor Yellow
  Remove-Item -Path "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

  # Clear User Temp
  Write-Host "Clearing User Temp..." -ForegroundColor Yellow
  Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue

  # Clear Internet Explorer Cache
  Write-Host "Clearing Internet Explorer Cache..." -ForegroundColor Yellow
  Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue

  Write-Host "Cache clearing completed." -ForegroundColor Green
}

# Quick Access to Editing the Profile
function Edit-Profile {
  nvim $PROFILE.CurrentUserAllHosts
}
Set-Alias -Name ep -Value Edit-Profile

# Update and cleanup all scoop packages
function Update-Scoop {
  scoop update -a
  scoop cleanup -a
  scoop export -c > "$env:XDG_CONFIG_HOME\scoop\scoopfile.json"
}

# Open Winutil
function winutil {
  Invoke-RestMethod https://christitus.com/win | Invoke-Expression
}

# Open NixOS WSL
function nix {
  wsl -d NixOS --cd ~
}

# Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
  BellStyle = 'None'
  EditMode = 'Windows'
  HistoryNoDuplicates = $true
  HistorySearchCursorMovesToEnd = $true
  PredictionSource = 'History'
  PredictionViewStyle = 'InlineView'
}
Set-PSReadLineOption @PSReadLineOptions

# Custom key handlers
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteChar
Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
Set-PSReadLineKeyHandler -Chord 'Alt+d' -Function DeleteWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+LeftArrow' -Function BackwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+RightArrow' -Function ForwardWord
Set-PSReadLineKeyHandler -Chord 'Ctrl+z' -Function Undo
Set-PSReadLineKeyHandler -Chord 'Ctrl+y' -Function Redo

# Custom functions for PSReadLine
Set-PSReadLineOption -AddToHistoryHandler {
  param($line)
  $sensitive = @('password', 'secret', 'token', 'apikey', 'connectionstring')
  $hasSensitive = $sensitive | Where-Object { $line -match $_ }
  return ($null -eq $hasSensitive)
}

function Set-PredictionSource {
  Set-PSReadLineOption -PredictionSource HistoryAndPlugin
  Set-PSReadLineOption -MaximumHistoryCount 10000
}
Set-PredictionSource

# Dotnet CLI Autocompletion
$scriptblock = {
  param($wordToComplete, $commandAst, $cursorPosition)
  dotnet complete --position $cursorPosition $commandAst.ToString() |
    ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock
