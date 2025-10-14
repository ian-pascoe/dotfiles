# Imports
Import-Module Terminal-Icons -ErrorAction SilentlyContinue

# Starship
Invoke-Expression (&starship init powershell)

# Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Scoop search
. ([ScriptBlock]::Create((& scoop-search --hook | Out-String)))

# Aliases
Set-Alias -Name ls -Value lsd
function ll {
  lsd -l $args
}
function lla {
  lsd -la $args
}

function catAlias {
  bat --paging=never $args
}
Set-Alias -Name cat -Value catAlias -Option AllScope

Set-Alias -Name cd -Value z -Option AllScope
Set-Alias -Name find -Value fd

function ln ($target, $link) {
  New-Item -Path $link -ItemType SymbolicLink -Value $target
}

# WSL fallback for command not found
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
  param($CommandName, $CommandLookupEventArgs)

  # Check if WSL is available
  if (Get-Command wsl -ErrorAction SilentlyContinue) {
    # Check if the command exists in WSL
    $wslCheck = wsl which $CommandName 2>$null
    if ($LASTEXITCODE -eq 0 -and $wslCheck) {
      $currentDir = (Get-Location).Path.Replace('\','\\')
      # Create a function that will handle the WSL call
      $functionName = "WSLFallback_$CommandName"
      $functionBody = @"
function global:$functionName {
   `$convertedArgs = @()
   foreach (`$arg in `$args) {
     # Check if argument is in --option=path format
     if (`$arg -match '^(--[^=]+=)(.+)$') {
       `$optionPart = `$Matches[1]
       `$pathPart = `$Matches[2]
       
       # Try to resolve the path part
       try {
         `$resolvedPath = [System.IO.Path]::GetFullPath(`$pathPart)
         `$windowsPath = `$resolvedPath
         `$wslPath = (wsl wslpath -a -u `$windowsPath.Replace('\','\\')).Trim()
         `$convertedArgs += `$optionPart + `$wslPath
       }
       catch {
         # If path part is not valid, use original argument
         `$convertedArgs += `$arg
       }
     }
     else {
       # Try to resolve the argument as a standalone path
       try {
         `$resolvedPath = [System.IO.Path]::GetFullPath(`$arg)
         `$windowsPath = `$resolvedPath
         `$wslPath = (wsl wslpath -a -u `$windowsPath.Replace('\','\\')).Trim()
         `$convertedArgs += `$wslPath
       }
       catch {
         # If it's not a valid path, use the argument as-is
         `$convertedArgs += `$arg
       }
     }
   }
   # Convert current PowerShell directory to WSL path and execute there
   `$wslCurrentDir = (wsl wslpath -a -u $currentDir).Trim()
   
   wsl --cd `$wslCurrentDir $CommandName @convertedArgs
}
"@
      
      # Execute the function definition
      Invoke-Expression $functionBody
      
      # Set the command to our new function
      $CommandLookupEventArgs.Command = Get-Command $functionName
    }
  }
}
