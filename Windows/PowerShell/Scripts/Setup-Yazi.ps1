#Requires -RunAsAdministrator

try {
  if (-not (Test-Command -commandName ya)) {
    Write-Log -Message "Yazi not found, skipping setup" -Level Warning
    return
  }

  Set-EnvironmentVariable -Name YAZI_CONFIG_HOME -Value "$env:XDG_CONFIG_HOME\yazi" -Persist
  New-Symlink -Target "$PSScriptRoot\..\..\..\config\yazi" -Link "$env:YAZI_CONFIG_HOME" -Force
  
  Write-SetupLog -Message "Installing Yazi packages..." -Level Info
  ya pkg install
  
  $yaziAppDataPath = "$env:USERPROFILE\AppData\Roaming\yazi"
  if (Test-Path $yaziAppDataPath) {
    Write-SetupLog -Message "Setting ownership for Yazi AppData..." -Level Info
    & icacls $yaziAppDataPath /setowner $env:USERNAME /T /C | Out-Null
  }
  
  Write-SetupLog -Message "Yazi setup completed" -Level Success
} catch {
  Write-SetupLog -Message "Failed to setup Yazi: $_" -Level Error
  throw
}
