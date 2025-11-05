#Requires -RunAsAdministrator

$taskName = "VcXsrv"

$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
  if ($existingTask.State -eq 'Running') {
    Stop-ScheduledTask -TaskName $taskName
    Write-Host "Stopped existing task: $taskName" -ForegroundColor Yellow
  }
  Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}
Stop-Process -Name vcxsrv -Force -ErrorAction SilentlyContinue

$vcxsrvPath = "$env:XDG_CONFIG_HOME\vcxsrv"
New-Symlink -Target "$PSScriptRoot\..\..\..\config\vcxsrv" -Link $vcxsrvPath -Force

$cmd = "$env:SCOOP\apps\vcxsrv\current\xlaunch.exe"
$cmdArgs = "-run `"$env:XDG_CONFIG_HOME\vcxsrv\config.xlaunch`""
$action = New-ScheduledTaskAction -Execute "$cmd" -Argument "$cmdArgs"
$trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
  
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "VcXsrv X Server Startup"
  
Write-Host "Created scheduled task: $taskName" -ForegroundColor Green
  
$task = Get-ScheduledTask -TaskName $taskName
if ($task.State -ne 'Running') {
  Start-ScheduledTask -TaskName $taskName
  Write-Host "Started task: $taskName" -ForegroundColor Cyan
}
