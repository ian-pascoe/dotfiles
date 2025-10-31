#Requires -RunAsAdministrator

$taskName = "GlazeWM"

$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
  if ($existingTask.State -eq 'Running') {
    Stop-ScheduledTask -TaskName $taskName
    Write-Host "Stopped existing task: $taskName" -ForegroundColor Yellow
  }
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}
Stop-Process -Name glazewm -Force -ErrorAction SilentlyContinue

$glazewmPath = "$env:USERPROFILE\.glzr\glazewm"
New-Symlink -Target "$PSScriptRoot\..\..\..\config\glazewm" -Link $glazewmPath -Force

$cliCmd = "$env:SCOOP\apps\glazewm\current\cli\glazewm.exe start"
$action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -Command `"$cliCmd`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
  
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Glaze Window Manager Startup"
  
Write-Host "Created scheduled task: $taskName" -ForegroundColor Green
  
$task = Get-ScheduledTask -TaskName $taskName
if ($task.State -ne 'Running') {
  Start-ScheduledTask -TaskName $taskName
  Write-Host "Started task: $taskName" -ForegroundColor Cyan
}
