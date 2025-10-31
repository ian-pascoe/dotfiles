
#Requires -RunAsAdministrator

$taskName = "YASB"

$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
  if ($existingTask.State -eq 'Running') {
    Stop-ScheduledTask -TaskName $taskName
    Write-Host "Stopped existing task: $taskName" -ForegroundColor Yellow
  }
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}
Stop-Process -Name YasbBar -Force -ErrorAction SilentlyContinue

$yasbPath = "$env:XDG_CONFIG_HOME\yasb"
New-Symlink -Target "$PSScriptRoot\..\..\..\config\yasb" -Link $yasbPath -Force

$cmd = "$env:SCOOP\apps\yasb\current\yasb.exe"
$action = New-ScheduledTaskAction -Execute "$cmd"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
  
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "YASB Status Bar Startup"
  
Write-Host "Created scheduled task: $taskName" -ForegroundColor Green
  
$task = Get-ScheduledTask -TaskName $taskName
if ($task.State -ne 'Running') {
  Start-ScheduledTask -TaskName $taskName
  Write-Host "Started task: $taskName" -ForegroundColor Cyan
}
