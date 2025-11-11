<#
.SYNOPSIS
  Setup Windows environment with dotfiles and configurations.
.DESCRIPTION
  This script sets up the Windows environment by linking dotfiles, installing packages via Scoop,
  configuring applications, and optionally setting up WSL with NixOS.
.PARAMETER DotfilesDir
  The directory containing the dotfiles repository. Default is the parent directory of the script, which should be correct.
.PARAMETER ScoopDir
  The directory for Scoop installation. Default is "$env:USERPROFILE\scoop".
.PARAMETER SkipWindows
  If specified, skips the Windows-specific setup.
.PARAMETER SkipWSL
  If specified, skips the WSL setup.
.PARAMETER SkipTheme
  If specified, skips the theme application.
.EXAMPLE
  .\setup.ps1
  Runs the full setup for Windows and WSL.
#>
#Requires -RunAsAdministrator
param(
  [string]$DotfilesDir = "$PSScriptRoot\..",
  [string]$ScoopDir = "$env:USERPROFILE\scoop",
  [switch]$SkipWindows = $false,
  [switch]$SkipWSL = $false,
  [switch]$SkipTheme = $false
)
Install-Module -Name PSReadLine -Force -Scope CurrentUser
Install-Module -Name PowerShell-Yaml -Force -Scope CurrentUser
Install-Module -Name Terminal-Icons -Force -Scope CurrentUser

# source the powershell profile
try {
  . "$PSScriptRoot/PowerShell/profile.ps1"
} catch {
  Write-Error "Failed to load PowerShell profile: $_"
  exit 1
}

# Validate required functions are available
$requiredFunctions = @('Test-Command', 'Write-Log', 'Invoke-WithErrorHandling', 'Add-ToEnvironmentVariable', 'New-Symlink', 'Set-EnvironmentVariable')
foreach ($func in $requiredFunctions) {
  if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
    Write-Error "Required function '$func' not found in profile. Setup cannot continue."
    exit 1
  }
}

if (-not $SkipWindows) {
  Write-Log -Message "Starting Windows setup..." -Level Info
  
  Update-Powershell

  Invoke-WithErrorHandling -ErrorMessage "Failed to update winget packages" -ContinueOnError -ScriptBlock {
    Write-Log -Message "Updating installed winget packages..." -Level Info
    winget upgrade --all --silent --accept-source-agreements --accept-package-agreements
  }

  # setup important env vars
  Write-Log -Message "Configuring environment variables..." -Level Info
  Set-EnvironmentVariable -Name HOME -Value "$env:HOME" -Persist
  Set-EnvironmentVariable -Name EDITOR -Value "nvim" -Persist
  Add-ToEnvironmentVariable -Path "$env:HOME\.local\bin" -VariableName PATH -Prepend -Level User
  Set-EnvironmentVariable -Name POWERSHELL_TELEMETRY_OPTOUT -Value "true" -Persist
  Add-ToEnvironmentVariable -Path "$env:HOME\Documents\PowerShell\Modules" -VariableName PSModulePath -Level User
  Add-ToEnvironmentVariable -Path "$env:HOME\Documents\WindowsPowerShell\Modules" -VariableName PSModulePath -Level User
  Set-EnvironmentVariable -Name XDG_BIN_HOME -Value "$env:HOME\.local\bin" -Persist
  Set-EnvironmentVariable -Name XDG_CACHE_HOME -Value "$env:HOME\.cache" -Persist
  Set-EnvironmentVariable -Name XDG_CONFIG_HOME -Value "$env:XDG_CONFIG_HOME" -Persist
  Set-EnvironmentVariable -Name XDG_DATA_HOME -Value "$env:HOME\.local\share" -Persist
  Set-EnvironmentVariable -Name XDG_DESKTOP_DIR -Value "$env:HOME\Desktop" -Persist
  Set-EnvironmentVariable -Name XDG_DOWNLOAD_DIR -Value "$env:HOME\Downloads" -Persist
  Set-EnvironmentVariable -Name THEMES_DIR -Value "$env:HOME\.themes" -Persist

  # link powershell profile/config
  Write-Log -Message "Linking PowerShell profiles..." -Level Info
  Invoke-WithErrorHandling -ErrorMessage "Failed to setup PowerShell profile" -ScriptBlock {
    if (-not (Test-Path "$env:HOME\Documents\PowerShell")) {
      New-Item -ItemType Directory -Path "$env:HOME\Documents\PowerShell" | Out-Null
    }
    New-Symlink -Target "$PSScriptRoot\PowerShell\profile.ps1" -Link "$env:HOME\Documents\PowerShell\profile.ps1" -Force
    New-Symlink -Target "$PSScriptRoot\PowerShell\powershell.config.json" -Link "$env:HOME\Documents\PowerShell\powershell.config.json" -Force

    if (-not (Test-Path "$env:HOME\Documents\WindowsPowerShell")) {
      New-Item -ItemType Directory -Path "$env:HOME\Documents\WindowsPowerShell" | Out-Null
    }
    New-Symlink -Target "$PSScriptRoot\WindowsPowerShell\profile.ps1" -Link "$env:HOME\Documents\WindowsPowerShell\profile.ps1" -Force
  }

  # setup local bin
  Write-Log -Message "Setting up local bin directory..." -Level Info
  Invoke-WithErrorHandling -ErrorMessage "Failed to setup local bin" -ScriptBlock {
    if (-not (Test-Path "$env:XDG_BIN_HOME")) {
      New-Item -ItemType Directory -Path "$env:XDG_BIN_HOME" | Out-Null
    }

    $scripts = Get-ChildItem -Path "$PSScriptRoot\..\bin" -Filter *.ps1
    foreach ($script in $scripts) {
      New-Symlink -Target $script.FullName -Link "$env:XDG_BIN_HOME\$($script.Name)" -Force
    }
  }

  # setup scoop
  if (-not (Test-Command -commandName scoop)) {
    Write-Log -Message "Installing Scoop package manager..." -Level Info
    Invoke-WithErrorHandling -ErrorMessage "Failed to install Scoop" -ScriptBlock {
      Set-EnvironmentVariable -Name SCOOP -Value $ScoopDir -Persist
      Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
      Invoke-Expression "& {$(Invoke-RestMethod -Uri https://get.scoop.sh)} -RunAsAdmin"
      
      # Verify Scoop was installed
      if (-not (Test-Command -commandName scoop)) {
        throw "Scoop installation completed but 'scoop' command not found"
      }
    }
  } else {
    if ($env:SCOOP -ne $ScoopDir) {
      Write-Log -Message "Existing SCOOP environment variable does not match -ScoopDir. No changes will be made to the scoop path." -Level Warning
    }
  }

  # install packages
  Write-Log -Message "Installing Scoop packages..." -Level Info
  Invoke-WithErrorHandling -ErrorMessage "Failed to import Scoop packages" -ContinueOnError -ScriptBlock {
    if (-not (Test-Path "$PSScriptRoot\..\config\scoop\scoopfile.json")) {
      throw "Scoopfile not found at $PSScriptRoot\..\config\scoop\scoopfile.json"
    }
    scoop import "$PSScriptRoot\..\config\scoop\scoopfile.json"
  }
  
  Invoke-WithErrorHandling -ErrorMessage "Failed to update/cleanup Scoop packages" -ContinueOnError -ScriptBlock {
    scoop update -a
    scoop cleanup -a
  }

  # configure apps/links
  Write-Log -Message "Configuring application symlinks..." -Level Info
  Invoke-WithErrorHandling -ErrorMessage "Failed to setup config links" -ScriptBlock {
    New-Symlink -Target "$PSScriptRoot\..\themes" -Link "$env:THEMES_DIR" -Force

    if (-not (Test-Path "$env:XDG_CONFIG_HOME")) {
      New-Item -ItemType Directory -Path "$env:XDG_CONFIG_HOME" | Out-Null
    }

    # bat
    Set-EnvironmentVariable -Name BAT_CONFIG_DIR -Value "$env:XDG_CONFIG_HOME\bat" -Persist
    New-Symlink -Target "$PSScriptRoot\..\config\bat" -Link "$env:BAT_CONFIG_DIR" -Force

    # btop
    if (Test-Path "$env:SCOOP\apps\btop\current") {
      New-Symlink -Target "$PSScriptRoot\..\config\btop\btop.conf" -Link "$env:SCOOP\apps\btop\current\btop.conf" -Force
    }
    if (Test-Path "$env:SCOOP\persist\btop") {
      New-Symlink -Target "$PSScriptRoot\..\config\btop\btop.conf" -Link "$env:SCOOP\persist\btop\btop.conf" -Force
    }

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
  }

  # apps with more involved setup
  Write-Log -Message "Running application-specific setup scripts..." -Level Info
  
  $setupScripts = @(
    "Setup-AutoHotkey.ps1",
    "Setup-FlowLauncher.ps1",
    "Setup-GlazeWM.ps1",
    "Setup-VcXsrv.ps1",
    "Setup-YASB.ps1",
    "Setup-Yazi.ps1",
    "Setup-Misc.ps1"
  )
  
  foreach ($script in $setupScripts) {
    $scriptPath = "$PSScriptRoot\PowerShell\Scripts\$script"
    Invoke-WithErrorHandling -ErrorMessage "Failed to run $script" -ContinueOnError -ScriptBlock {
      if (-not (Test-Path $scriptPath)) {
        throw "Script not found: $scriptPath"
      }
      & $scriptPath
    }
  }
  
  Write-Log -Message "Windows setup completed" -Level Success
}

if (-not $SkipWSL) {
  Write-Log -Message "Starting WSL setup..." -Level Info
  
  Invoke-WithErrorHandling -ErrorMessage "Failed to setup WSL config" -ScriptBlock {
    New-Symlink -Target "$PSScriptRoot\..\Windows\wslconfig" -Link "$env:HOME\.wslconfig" -Force
  }
  
  Invoke-WithErrorHandling -ErrorMessage "Failed to install WSL" -ContinueOnError -ScriptBlock {
    wsl --install --no-distribution
    wsl --update
  }
  
  Invoke-WithErrorHandling -ErrorMessage "Failed to setup NixOS distribution" -ScriptBlock {
    $wslDistroList = (wsl -l -v) -replace '\x00', ''
    if (-not ($wslDistroList | Select-String -Pattern "\s*NixOS\s")) {
      Write-Log -Message "Downloading NixOS WSL distribution..." -Level Info
      $nixosGitHubApiUrl = "https://api.github.com/repos/nix-community/NixOS-WSL/releases/latest"
      $nixosReleaseInfo = Invoke-RestMethod -Uri $nixosGitHubApiUrl
      
      if (-not $nixosReleaseInfo) {
        throw "Failed to fetch NixOS release information"
      }
      
      $nixosAsset = $nixosReleaseInfo.assets | Where-Object { $_.name -like "*.wsl" } | Select-Object -First 1
      if (-not $nixosAsset) {
        throw "No WSL distribution found in latest NixOS release"
      }
      
      $nixosUrl = $nixosAsset.browser_download_url
      $nixosWslPath = "$env:TEMP\NixOS.wsl"
      
      Invoke-WebRequest -Uri $nixosUrl -OutFile $nixosWslPath
      
      if (-not (Test-Path $nixosWslPath)) {
        throw "Failed to download NixOS WSL distribution"
      }
      
      Write-Log -Message "Installing NixOS WSL distribution..." -Level Info
      $installPath = "$env:HOME\.wsl\nixos"
      if (-not (Test-Path (Split-Path $installPath -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $installPath -Parent) -Force | Out-Null
      }
      
      wsl --import NixOS $installPath $nixosWslPath --version 2
      Remove-Item $nixosWslPath -Force -ErrorAction SilentlyContinue
      Write-Log -Message "NixOS distribution installed" -Level Success
    } else {
      Write-Log -Message "NixOS distribution already installed" -Level Info
    }
  }

  Invoke-WithErrorHandling -ErrorMessage "Failed to export certificates" -ContinueOnError -ScriptBlock {
    $allCertsPath = "$env:XDG_CACHE_HOME\certificates"
    Write-Log -Message "Exporting certificates..." -Level Info
    
    $certScript = "$PSScriptRoot\..\bin\Get-AllCertificates.ps1"
    if (-not (Test-Path $certScript)) {
      throw "Certificate export script not found: $certScript"
    }
    
    & $certScript -OutputDir "$allCertsPath"
    
    if (-not (Test-Path "$allCertsPath\ca-bundle.crt")) {
      throw "Certificate bundle was not created successfully"
    }
  }

  Invoke-WithErrorHandling -ErrorMessage "Failed to run WSL setup script" -ScriptBlock {
    $wslSetupScript = "$PSScriptRoot\setup-wsl.sh"
    if (-not (Test-Path $wslSetupScript)) {
      throw "WSL setup script not found: $wslSetupScript"
    }
    
    $allCertsPath = "$env:XDG_CACHE_HOME\certificates"
    $wslSetupScriptPath = Get-WSLPath $wslSetupScript
    $wslWindowsHomePath = Get-WSLPath "$env:HOME"
    $wslDotfilesDir = Get-WSLPath "$DotfilesDir"
    $wslCertBundlePath = Get-WSLPath "$allCertsPath\ca-bundle.crt"
    
    $scriptCmd = "chmod +x '$wslSetupScriptPath' && '$wslSetupScriptPath' '$env:USERNAME' '$wslWindowsHomePath' '$wslDotfilesDir' '$wslCertBundlePath'"
    Write-Log -Message "Running WSL setup script..." -Level Info
    
    wsl -d NixOS --user root -- bash -c "$scriptCmd"
    if ($LASTEXITCODE -ne 0) {
      throw "WSL setup script exited with code $LASTEXITCODE"
    }
  }
  
  Write-Log -Message "WSL setup completed" -Level Success
}

if (-not $SkipTheme) {
  Write-Log -Message "Configuring theme..." -Level Info
  
  Invoke-WithErrorHandling -ErrorMessage "Failed to setup theme" -ContinueOnError -ScriptBlock {
    if (-not (Test-Path "$env:XDG_CONFIG_HOME\theme")) {
      Write-Log -Message "Linking Rose Pine (default) theme" -Level Info
      Set-Theme "Rose-Pine"
    } else {
      Write-Log -Message "Reapplying existing theme" -Level Info
      $themeLink = Get-Item "$env:XDG_CONFIG_HOME\theme" -ErrorAction Stop
      if ($themeLink.Target) {
        $theme = $themeLink.Target | Split-Path -Leaf
        Set-Theme $theme
      } else {
        Write-Log -Message "Theme link invalid, setting Rose Pine as default" -Level Warning
        Set-Theme "Rose-Pine"
      }
    }
  }
  
  Write-Log -Message "Theme configuration completed" -Level Success
}

Write-Log -Message "Setup script completed successfully" -Level Success
