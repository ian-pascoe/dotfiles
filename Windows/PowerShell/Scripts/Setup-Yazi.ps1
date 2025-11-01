#Requires -RunAsAdministrator

Set-EnvironmentVariable -Name YAZI_CONFIG_HOME -Value "$env:XDG_CONFIG_HOME\yazi" -Persist
New-Symlink -Target "$PSScriptRoot\..\..\..\config\yazi" -Link "$env:YAZI_CONFIG_HOME" -Force
ya pkg install
$yaziAppDataPath = "$env:USERPROFILE\AppData\Roaming\yazi"
if (Test-Path $yaziAppDataPath) {
  & icacls $yaziAppDataPath /setowner $env:USERNAME /T /C
}
