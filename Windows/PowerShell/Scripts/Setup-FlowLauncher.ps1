#Requires -RunAsAdministrator

try {
  $taskName = "FlowLauncher"
  $cmd = "$env:SCOOP\apps\flow-launcher\current\Flow.Launcher.exe"
  
  if (-not (Test-Path $cmd)) {
    Write-SetupLog -Message "Flow Launcher not found at $cmd, skipping setup" -Level Warning
    return
  }

  $flowLauncherSettingsPath = "$env:SCOOP\persist\flow-launcher\UserData\Settings\Settings.json"
  New-Symlink -Target "$PSScriptRoot\..\..\..\config\flow-launcher\Settings.json" -Link $flowLauncherSettingsPath -Force

  # Check if task needs to be created or updated
  if (Test-ScheduledTaskNeedsUpdate -TaskName $taskName -ExecutablePath $cmd) {
    Write-SetupLog -Message "Creating/updating scheduled task: $taskName" -Level Info
    
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
      if ($existingTask.State -eq 'Running') {
        Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
      }
      Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    Stop-Process -Name Flow.Launcher -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    
    $action = New-ScheduledTaskAction -Execute $cmd
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
      
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "Flow Launcher Command Launcher" | Out-Null
      
    Write-SetupLog -Message "Created scheduled task: $taskName" -Level Success
  } else {
    Write-SetupLog -Message "Scheduled task $taskName is up to date" -Level Info
  }
    
  $task = Get-ScheduledTask -TaskName $taskName
  if ($task.State -ne 'Running') {
    Start-ScheduledTask -TaskName $taskName
    Write-SetupLog -Message "Started task: $taskName" -Level Info
  }
} catch {
  Write-SetupLog -Message "Failed to setup Flow Launcher: $_" -Level Error
  throw
}
