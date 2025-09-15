#Requires -RunAsAdministrator

param(
    [switch]$Force = $false
)

Write-Host "Installing dotfiles for Windows..." -ForegroundColor Green

$DotfilesPath = $PSScriptRoot
$UserProfile = $env:USERPROFILE
$LocalAppData = $env:LOCALAPPDATA
$AppData = $env:APPDATA

function New-SymbolicLink {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$IsDirectory = $false
    )
    
    if (Test-Path $Target) {
        if ($Force) {
            Write-Host "Removing existing: $Target" -ForegroundColor Yellow
            Remove-Item $Target -Recurse -Force
        } else {
            Write-Host "Already exists: $Target (use -Force to overwrite)" -ForegroundColor Yellow
            return
        }
    }
    
    $TargetDir = Split-Path $Target -Parent
    if (-not (Test-Path $TargetDir)) {
        Write-Host "Creating directory: $TargetDir" -ForegroundColor Cyan
        New-Item -Path $TargetDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        if ($IsDirectory) {
            New-Item -Path $Target -ItemType Junction -Value $Source | Out-Null
        } else {
            New-Item -Path $Target -ItemType SymbolicLink -Value $Source | Out-Null
        }
        Write-Host "Linked: $Source -> $Target" -ForegroundColor Green
    } catch {
        Write-Host "Failed to link: $Source -> $Target ($($_.Exception.Message))" -ForegroundColor Red
    }
}

# PowerShell Profile
$PowerShellProfilePath = "$UserProfile\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
New-SymbolicLink -Source "$DotfilesPath\Windows\Powershell\Microsoft.PowerShell_profile.ps1" -Target $PowerShellProfilePath

# PowerShell Config
$PowerShellConfigPath = "$UserProfile\Documents\PowerShell\powershell.config.json"
New-SymbolicLink -Source "$DotfilesPath\Windows\Powershell\powershell.config.json" -Target $PowerShellConfigPath

# Starship config
$StarshipConfigPath = "$UserProfile\.config\starship.toml"
New-SymbolicLink -Source "$DotfilesPath\.config\starship.toml" -Target $StarshipConfigPath

# Scoop config
$ScoopConfigPath = "$UserProfile\.config\scoop\config.json"
New-SymbolicLink -Source "$DotfilesPath\.config\scoop\config.json" -Target $ScoopConfigPath

# AutoHotkey scripts
$AhkDir = "$UserProfile\.config\autohotkey"
New-SymbolicLink -Source "$DotfilesPath\.config\autohotkey" -Target $AhkDir -IsDirectory

# Bat config
$BatConfigDir = "$AppData\bat"
New-SymbolicLink -Source "$DotfilesPath\.config\bat" -Target $BatConfigDir -IsDirectory

# Ghostty config
$GhosttyConfigDir = "$AppData\ghostty"
New-SymbolicLink -Source "$DotfilesPath\.config\ghostty" -Target $GhosttyConfigDir -IsDirectory

# LSD config
$LsdConfigDir = "$AppData\lsd"
New-SymbolicLink -Source "$DotfilesPath\.config\lsd" -Target $LsdConfigDir -IsDirectory

# Neovim config
$NvimConfigDir = "$LocalAppData\nvim"
New-SymbolicLink -Source "$DotfilesPath\.config\nvim" -Target $NvimConfigDir -IsDirectory

# OpenCode config
$OpenCodeConfigDir = "$UserProfile\.config\opencode"
New-SymbolicLink -Source "$DotfilesPath\.config\opencode" -Target $OpenCodeConfigDir -IsDirectory

# Winfetch config
$WinfetchConfigPath = "$UserProfile\.config\winfetch\config.ps1"
New-SymbolicLink -Source "$DotfilesPath\.config\winfetch\config.ps1" -Target $WinfetchConfigPath

# Yazi config
$YaziConfigDir = "$AppData\yazi\config"
New-SymbolicLink -Source "$DotfilesPath\.config\yazi" -Target $YaziConfigDir -IsDirectory

# YASB config (Yet Another Status Bar)
$YasbConfigDir = "$UserProfile\.config\yasb"
New-SymbolicLink -Source "$DotfilesPath\.config\yasb" -Target $YasbConfigDir -IsDirectory

# GlazeWM config
$GlazeWMConfigPath = "$UserProfile\.glzr\glazewm\config.yaml"
New-SymbolicLink -Source "$DotfilesPath\.glzr\glazewm\config.yaml" -Target $GlazeWMConfigPath

# Windows Subsystem for Linux config
$WslConfigPath = "$UserProfile\.wslconfig"
New-SymbolicLink -Source "$DotfilesPath\.wslconfig" -Target $WslConfigPath

# Git config (global)
$GitConfigPath = "$UserProfile\.gitconfig"
if (Test-Path "$DotfilesPath\.gitconfig") {
    New-SymbolicLink -Source "$DotfilesPath\.gitconfig" -Target $GitConfigPath
}

Write-Host "`nDotfiles installation completed!" -ForegroundColor Green
Write-Host "Note: Some applications may need to be restarted to pick up the new configurations." -ForegroundColor Yellow
