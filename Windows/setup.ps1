<#
.SYNOPSIS
  Setup Windows environment with dotfiles and configurations.
.DESCRIPTION
  This script sets up the Windows environment by linking dotfiles, installing packages via Scoop,
  configuring applications, and optionally setting up WSL with NixOS.
.PARAMETER DotfilesDir
  The directory containing the dotfiles. Default is the parent directory of the script.
.PARAMETER ScoopDir
  The directory for Scoop installation. Default is "$env:HOME\scoop".
.PARAMETER SkipWindows
  If specified, skips the Windows-specific setup.
.PARAMETER SkipWSL
  If specified, skips the WSL setup.
.PARAMETER SkipTheme
  If specified, skips the theme application.
.EXAMPLE
  .\setup.ps1 -DotfilesDir "C:\Users\User\dotfiles" -CustomProgramDir "D:\CustomPrograms" -ScoopDir "D:\Scoop"
#>
#Requires -RunAsAdministrator
param(
  [string]$DotfilesDir = "$PSScriptRoot\..",
  [string]$ScoopDir = "$env:HOME\scoop",
  [switch]$SkipWindows = $false,
  [switch]$SkipWSL = $false,
  [switch]$SkipTheme = $false
)

# source the powershell profile
. "$PSScriptRoot/PowerShell/profile.ps1"

if (-not $SkipWindows) {
  Update-Powershell

  # setup important env vars
  Set-EnvironmentVariable -Name HOME -Value "$env:HOME" -Persist
  if ($env:PATH -notlike "*$env:HOME\.local\bin*") {
    Set-EnvironmentVariable -Name PATH -Value "$env:HOME\.local\bin;$env:PATH" -Persist
  }
  Set-EnvironmentVariable -Name POWERSHELL_TELEMETRY_OPTOUT -Value "true" -Persist
  if ($env:PSModulePath -notlike "*$env:HOME\Documents\PowerShell\Modules*") {
    Set-EnvironmentVariable -Name PSModulePath -Value "$env:HOME\Documents\PowerShell\Modules;$env:PSModulePath" -Persist
  }
  if ($env:PSModulePath -notlike "*$env:HOME\Documents\WindowsPowerShell\Modules*") {
    Set-EnvironmentVariable -Name PSModulePath -Value "$env:HOME\Documents\WindowsPowerShell\Modules;$env:PSModulePath" -Persist
  }
  Set-EnvironmentVariable -Name XDG_BIN_HOME -Value "$env:HOME\.local\bin" -Persist
  Set-EnvironmentVariable -Name XDG_CACHE_HOME -Value "$env:HOME\.cache" -Persist
  Set-EnvironmentVariable -Name XDG_CONFIG_HOME -Value "$env:XDG_CONFIG_HOME" -Persist
  Set-EnvironmentVariable -Name XDG_DATA_HOME -Value "$env:HOME\.local\share" -Persist
  Set-EnvironmentVariable -Name XDG_DESKTOP_DIR -Value "$env:HOME\Desktop" -Persist
  Set-EnvironmentVariable -Name XDG_DOWNLOAD_DIR -Value "$env:HOME\Downloads" -Persist
  Set-EnvironmentVariable -Name THEMES_DIR -Value "$env:HOME\.themes" -Persist

  # link powershell profile/config
  if (-not (Test-Path "$env:HOME\Documents\PowerShell")) {
    New-Item -ItemType Directory -Path "$env:HOME\Documents\PowerShell"
  }
  New-Symlink -Target "$PSScriptRoot\PowerShell\profile.ps1" -Link "$env:HOME\Documents\PowerShell\profile.ps1" -Force
  New-Symlink -Target "$PSScriptRoot\PowerShell\powershell.config.json" -Link "$env:HOME\Documents\PowerShell\powershell.config.json" -Force

  if (-not (Test-Path "$env:HOME\Documents\WindowsPowerShell")) {
    New-Item -ItemType Directory -Path "$env:HOME\Documents\WindowsPowerShell"
  }
  New-Symlink -Target "$PSScriptRoot\WindowsPowerShell\profile.ps1" -Link "$env:HOME\Documents\WindowsPowerShell\profile.ps1" -Force

  # setup local bin
  if (-not (Test-Path "$env:XDG_BIN_HOME")) {
    New-Item -ItemType Directory -Path "$env:XDG_BIN_HOME"
  }

  $scripts = Get-ChildItem -Path "$PSScriptRoot\..\bin" -Filter *.ps1
  foreach ($script in $scripts) {
    New-Symlink -Target $script.FullName -Link "$env:XDG_BIN_HOME\$($script.Name)" -Force
  }

  # setup scoop
  if (-not (Test-Command -commandName scoop)) {
    Set-EnvironmentVariable -Name SCOOP -Value $ScoopDir -Persist
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-Expression "& {$(Invoke-RestMethod -Uri https://get.scoop.sh)} -RunAsAdmin"
  } else {
    if ($env:SCOOP -ne $ScoopDir) {
      Write-Host "WARNING: Existing SCOOP environment variable does not match -ScoopDir. No changes will be made to the scoop path." -ForegroundColor Yellow
    }
  }

  # install packages
  scoop import "$PSScriptRoot\..\config\scoop\scoopfile.json"
  scoop update -a && scoop cleanup -a

  # configure apps/links
  New-Symlink -Target "$PSScriptRoot\..\themes" -Link "$env:THEMES_DIR" -Force

  if (-not (Test-Path "$env:XDG_CONFIG_HOME")) {
    New-Item -ItemType Directory -Path "$env:XDG_CONFIG_HOME"
  }

  # alacritty
  if (-not (Test-Path "$env:APPDATA\alacritty")) {
    New-Item -ItemType Directory -Path "$env:APPDATA\alacritty"
  }
  New-Symlink -Target "$PSScriptRoot\..\config\alacritty\alacritty.toml" -Link "$env:APPDATA\alacritty\alacritty.toml" -Force

  # bat
  Set-EnvironmentVariable -Name BAT_CONFIG_DIR -Value "$env:XDG_CONFIG_HOME\bat" -Persist
  New-Symlink -Target "$PSScriptRoot\..\config\bat" -Link "$env:BAT_CONFIG_DIR" -Force

  # btop
  New-Symlink -Target "$PSScriptRoot\..\config\btop\btop.conf" -Link "$env:SCOOP\apps\btop\current\btop.conf" -Force
  New-Symlink -Target "$PSScriptRoot\..\config\btop\btop.conf" -Link "$env:SCOOP\persist\btop\btop.conf" -Force

  # k9s
  New-Symlink -Target "$PSScriptRoot\..\config\k9s" -Link "$env:LOCALAPPDATA\k9s" -Force

  # lsd
  New-Symlink -Target "$PSScriptRoot\..\config\lsd" -Link "$env:XDG_CONFIG_HOME\lsd" -Force

  # scoop
  New-Symlink -Target "$PSScriptRoot\..\config\scoop" -Link "$env:XDG_CONFIG_HOME\scoop" -Force

  # starship
  New-Symlink -Target "$PSScriptRoot\..\config\starship.toml" -Link "$env:XDG_CONFIG_HOME\starship.toml" -Force

  # winfetch
  Set-EnvironmentVariable -Name WINFETCH_CONFIG_PATH -Value "$env:XDG_CONFIG_HOME\winfetch\config.ps1" -Persist
  New-Symlink -Target "$PSScriptRoot\..\config\winfetch" -Link (& Split-Path "$env:WINFETCH_CONFIG_PATH" -Parent) -Force

  # apps with more involved setup
  & "$PSScriptRoot\PowerShell\Scripts\Setup-AutoHotkey.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-FlowLauncher.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-GlazeWM.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-VcXsrv.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-YASB.ps1"
  & "$PSScriptRoot\PowerShell\Scripts\Setup-Yazi.ps1"
}

if (-not $SkipWSL) {
  New-Symlink -Target "$PSScriptRoot\..\Windows\wslconfig" -Link "$env:HOME\.wslconfig" -Force
  wsl --install --no-distribution && wsl --update
  $wslDistroList = (wsl -l -v) -replace '\x00', ''
  if (-not ($wslDistroList | Select-String -Pattern "NixOS")) {
    $nixosGitHubApiUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
    $nixosReleaseInfo = Invoke-RestMethod -Uri $nixosGitHubApiUrl
    $nixosAsset = $nixosReleaseInfo.assets | Where-Object { $_.name -like "*.wsl" } | Select-Object -First 1
    $nixosUrl = $nixosAsset.browser_download_url
    $nixosWslPath = "$env:TEMP\NixOS.wsl"
    Write-Host "Downloading NixOS WSL distribution..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri $nixosUrl -OutFile $nixosWslPath
    Write-Host "Installing NixOS WSL distribution..." -ForegroundColor Cyan
    wsl --import NixOS "$env:HOME\WSL\NixOS" $nixosWslPath --version 2
    Remove-Item $nixosWslPath -Force -ErrorAction SilentlyContinue
    Write-Host "NixOS distribution installed." -ForegroundColor Green
  } else {
    Write-Host "NixOS distribution already installed." -ForegroundColor Green
  }

  $allCertsPath = "$env:XDG_CACHE_HOME\certificates"
  Write-Host "Exporting certificates..." -ForegroundColor Cyan
  & "$PSScriptRoot\..\bin\Get-AllCertificates.ps1" -OutputDir "$allCertsPath"

  $wslSetupScriptPath = Get-WSLPath "$PSScriptRoot\setup-wsl.sh"
  $wslDotfilesDir = Get-WSLPath "$DotfilesDir"
  $wslCertBundlePath = Get-WSLPath "$allCertsPath\ca-bundle.crt"
  $scriptCmd = "chmod +x '$wslSetupScriptPath' && '$wslSetupScriptPath' '$env:HOME' '$wslDotfilesDir' '$wslCertBundlePath'"
  Write-Host "Running WSL setup script..." -ForegroundColor Cyan
  wsl -d NixOS -- bash -c "$scriptCmd"
  Write-Host "WSL setup completed." -ForegroundColor Green
}

if (-not $SkipTheme) {
  if (-not (Test-Path "$env:XDG_CONFIG_HOME\theme")) {
    Write-Host "Linking Rose Pine (default) theme"
    Set-Theme "Rose-Pine"
  } else {
    Write-Host "Reapplying theme"
    $theme = (Get-Item "$env:XDG_CONFIG_HOME\theme").Target | Split-Path -Leaf
    Set-Theme $theme
  }
} 
