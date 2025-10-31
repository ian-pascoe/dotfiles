#Requires -RunAsAdministrator

$autohotkeyPath = "$env:XDG_CONFIG_HOME\autohotkey"
New-Symlink -Target "$PSScriptRoot\..\..\..\config\autohotkey" -Link $autohotkeyPath -Force

$ahkScripts = Get-ChildItem -Path $autohotkeyPath -Filter "*.ahk"
foreach ($script in $ahkScripts) {
  $taskName = "AutoHotkey_$($script.BaseName)"
  $scriptPath = $script.FullName
  
  $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
  if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
  }
  
  $action = New-ScheduledTaskAction -Execute "$env:SCOOP\apps\autohotkey\current\v2\AutoHotkey64.exe" -Argument "`"$scriptPath`""
  $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
  $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
  $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
  
  Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "AutoHotkey script: $($script.Name)"
  
  Write-Host "Created scheduled task: $taskName" -ForegroundColor Green
  
  $task = Get-ScheduledTask -TaskName $taskName
  if ($task.State -ne 'Running') {
    Start-ScheduledTask -TaskName $taskName
    Write-Host "Started task: $taskName" -ForegroundColor Cyan
  }
}
