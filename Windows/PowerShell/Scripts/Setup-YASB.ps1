#Requires -RunAsAdministrator

try {
  $taskName = "YASB"
  $cmd = "$env:SCOOP\apps\yasb\current\yasb.exe"
  
  if (-not (Test-Path $cmd)) {
    Write-SetupLog -Message "YASB not found at $cmd, skipping setup" -Level Warning
    return
  }

  $yasbPath = "$env:XDG_CONFIG_HOME\yasb"
  New-Symlink -Target "$PSScriptRoot\..\..\..\config\yasb" -Link $yasbPath -Force

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
    
    Stop-Process -Name YasbBar -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500

    $action = New-ScheduledTaskAction -Execute $cmd
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User "$env:USERDOMAIN\$env:USERNAME"
    $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew
      
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Description "YASB Status Bar Startup" | Out-Null
      
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
  Write-SetupLog -Message "Failed to setup YASB: $_" -Level Error
  throw
}
