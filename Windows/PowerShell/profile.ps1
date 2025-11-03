# Import Modules and External Profiles
# Ensure Terminal-Icons module is installed before importing
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
  Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}
Import-Module -Name Terminal-Icons

if(Get-Module -ListAvailable -Name gsudoModule) {
  Import-Module gsudoModule
} else {
  Write-Host "gsudoModule not found. Please install gsudo for elevated command support." -ForegroundColor Yellow
}

function Test-Command {
  param (
    [string]$commandName
  )
  return Get-Command $commandName -ErrorAction SilentlyContinue
}

function Update-PowerShell {
  try {
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
      $zipAsset = $latestReleaseInfo.assets | Where-Object { $_.name -like "*win-x64.zip" } | Select-Object -First 1
      $zipUrl = $zipAsset.browser_download_url
      $zipPath = "$env:TEMP\PowerShell-$latestVersion-win-x64.zip"
      Write-Host "Downloading PowerShell $latestVersion..." -ForegroundColor Cyan
      Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath
      Write-Host "Installing PowerShell..." -ForegroundColor Cyan
      Expand-Archive -Path $zipPath -DestinationPath "$env:CustomProgramFiles\PowerShell\$latestVersion" -Force
      New-Symlink -Target "$env:CustomProgramFiles\PowerShell\$latestVersion" -Link "$env:CustomProgramFiles\PowerShell\current" -Force
      Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
      Write-Host "PowerShell has been updated. Please restart your shell to reflect changes" -ForegroundColor Magenta
    } else {
      Write-Host "Your PowerShell is up to date." -ForegroundColor Green
    }
  } catch {
    Write-Error "Failed to update PowerShell. Error: $_"
  }
}

# starship
if (Test-Command -commandName "starship") {
  Invoke-Expression (&starship init powershell)
}

# zoxide
if (Test-Command -commandName "zoxide") {
  Invoke-Expression (& { (zoxide init powershell | Out-String) })
  Set-Alias -Name cd -Value z -Option AllScope
}

# scoop-search
if (Test-Command -commandName "scoop-search") {
  . ([ScriptBlock]::Create((& scoop-search --hook | Out-String)))
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

# Open Winutil
function winutil {
  Invoke-RestMethod https://chistitus.com/win | Invoke-Expression
}

# Enhanced PowerShell Experience
# Enhanced PSReadLine Configuration
$PSReadLineOptions = @{
  EditMode = 'Windows'
  HistoryNoDuplicates = $true
  HistorySearchCursorMovesToEnd = $true
  PredictionSource = 'History'
  PredictionViewStyle = 'ListView'
  BellStyle = 'None'
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
  # Improved prediction settings
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

# WSL fallback for command not found
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
  param($CommandName, $CommandLookupEventArgs)

  # Check if WSL is available
  if (Get-Command wsl -ErrorAction SilentlyContinue) {
    # Check if the command exists in WSL
    $wslCheck = wsl which $CommandName 2>$null
    if ($LASTEXITCODE -eq 0 -and $wslCheck) {
      $currentDir = (Get-Location).Path.Replace('\','\\')
      # Create a function that will handle the WSL call
      $functionName = "WSLFallback_$CommandName"
      $functionBody = @"
function global:$functionName {
   `$convertedArgs = @()
   foreach (`$arg in `$args) {
     # Check if argument is in --option=path format
     if (`$arg -match '^(--[^=]+=)(.+)$') {
       `$optionPart = `$Matches[1]
       `$pathPart = `$Matches[2]
       
       # Try to resolve the path part
       try {
         `$resolvedPath = [System.IO.Path]::GetFullPath(`$pathPart)
         `$windowsPath = `$resolvedPath
         `$wslPath = (wsl wslpath -a -u `$windowsPath.Replace('\','\\')).Trim()
         `$convertedArgs += `$optionPart + `$wslPath
       }
       catch {
         # If path part is not valid, use original argument
         `$convertedArgs += `$arg
       }
     }
     else {
       # Try to resolve the argument as a standalone path
       try {
         `$resolvedPath = [System.IO.Path]::GetFullPath(`$arg)
         `$windowsPath = `$resolvedPath
         `$wslPath = (wsl wslpath -a -u `$windowsPath.Replace('\','\\')).Trim()
         `$convertedArgs += `$wslPath
       }
       catch {
         # If it's not a valid path, use the argument as-is
         `$convertedArgs += `$arg
       }
     }
   }
   # Convert current PowerShell directory to WSL path and execute there
   `$wslCurrentDir = (wsl wslpath -a -u $currentDir).Trim()
   
   wsl --cd `$wslCurrentDir $CommandName @convertedArgs
}
"@
      
      # Execute the function definition
      Invoke-Expression $functionBody
      
      # Set the command to our new function
      $CommandLookupEventArgs.Command = Get-Command $functionName
    }
  }
}
