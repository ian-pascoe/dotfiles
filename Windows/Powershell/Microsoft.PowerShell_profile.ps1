# Imports
Import-Module PSReadLine
Import-Module Terminal-Icons

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
. ([ScriptBlock]::Create((& scoop-search --hook | Out-String)))

# Aliases
Set-Alias -Name ls -Value lsd
Set-Alias -Name cat -Value bat
Set-Alias -Name cd -Value z -Option AllScope
Set-Alias -Name find -Value fd

function Make-Link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target
}

# Function to convert Windows paths to WSL paths using wslpath
function Convert-WindowsPathToWsl {
    param([string]$Path)
    
    if ([string]::IsNullOrEmpty($Path)) {
        return $Path
    }
    
    # Handle quoted paths
    $isQuoted = $Path.StartsWith('"') -and $Path.EndsWith('"')
    if ($isQuoted) {
        $Path = $Path.Substring(1, $Path.Length - 2)
    }
    
    # Check if this looks like a Windows path that should be converted
    $shouldConvert = $false
    
    # Absolute Windows paths (C:\path\to\file)
    if ($Path -match '^[A-Za-z]:[\\\/]') {
        $shouldConvert = $true
    }
    # Relative paths with backslashes
    elseif ($Path.Contains('\')) {
        $shouldConvert = $true
    }
    # UNC paths (\\server\share) - let wslpath handle these
    elseif ($Path.StartsWith('\\')) {
        $shouldConvert = $true
    }
    
    if ($shouldConvert) {
        try {
            # Use wslpath to convert the path
            $wslPath = wsl wslpath -u $Path 2>$null
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($wslPath)) {
                # Remove any trailing newline from wslpath output
                $wslPath = $wslPath.Trim()
                
                # Re-add quotes if the original path was quoted
                if ($isQuoted) {
                    return "`"$wslPath`""
                }
                return $wslPath
            }
        }
        catch {
            # If wslpath fails, fall back to simple backslash replacement
            $wslPath = $Path.Replace('\', '/')
            if ($isQuoted) {
                return "`"$wslPath`""
            }
            return $wslPath
        }
    }
    
    # Path doesn't need conversion or conversion failed, return original
    if ($isQuoted) {
        return "`"$Path`""
    }
    return $Path
}

# Function to convert arguments for WSL
function Convert-ArgsForWsl {
    param([string[]]$Args)
    
    $convertedArgs = @()
    
    foreach ($arg in $Args) {
        # Skip empty arguments
        if ([string]::IsNullOrEmpty($arg)) {
            $convertedArgs += $arg
            continue
        }
        
        # Handle --option=value syntax (e.g., --path="C:\temp", --config=.\config.ini)
        if ($arg -match '^(-{1,2}[^=]+)=(.+)$') {
            $optionName = $matches[1]
            $optionValue = $matches[2]
            
            # Check if the value part looks like a Windows path
            if ($optionValue -match '^[A-Za-z]:[\\\/]|^\\\\[^\\]+\\[^\\]+|^\.[\\\/]|^\.\.[\\\/]|[\\]') {
                $convertedValue = Convert-WindowsPathToWsl -Path $optionValue
                $convertedArgs += "$optionName=$convertedValue"
            } else {
                $convertedArgs += $arg
            }
        }
        # Handle standalone paths
        elseif ($arg -match '^[A-Za-z]:[\\\/]|^\\\\[^\\]+\\[^\\]+|^\.[\\\/]|^\.\.[\\\/]|[\\]') {
            $convertedArgs += Convert-WindowsPathToWsl -Path $arg
        }
        # Handle current directory reference
        elseif ($arg -eq '.') {
            $convertedArgs += '.'
        }
        # Handle parent directory reference  
        elseif ($arg -eq '..') {
            $convertedArgs += '..'
        }
        # Handle arguments that might contain paths in other formats
        # Check for space-separated option value pairs (e.g., "--path C:\temp")
        # This is handled naturally by PowerShell's argument parsing, so no special handling needed
        else {
            $convertedArgs += $arg
        }
    }
    
    return $convertedArgs
}

# Override the CommandNotFoundAction to create WSL command wrappers
$ExecutionContext.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)
    
    # Skip if command contains path separators (likely a script/executable path)
    if ($CommandName.Contains('\') -or $CommandName.Contains('/')) {
        return
    }
    
    # Try to find the command in WSL
    try {
        $wslCheck = wsl which $CommandName 2>$null
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($wslCheck)) {
            # Create a wrapper function for this WSL command
            New-WslCommandWrapper -CommandName $CommandName
            
            # Stop the search - the function is now available
            $CommandLookupEventArgs.StopSearch = $true
        }
    }
    catch {
        # If WSL check fails, don't forward the command
        return
    }
}

# Helper function to manually forward commands to WSL (optional)
function Invoke-WslCommand {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        [Parameter(ValueFromRemainingArguments=$true)]
        [string[]]$Arguments
    )
    
    $wslArgs = Convert-ArgsForWsl -Args $Arguments
    
    if ($wslArgs.Count -gt 0) {
        wsl $Command @wslArgs
    } else {
        wsl $Command
    }
}

# Alias for the helper function
Set-Alias -Name wslc -Value Invoke-WslCommand

Write-Host "PowerShell profile loaded with WSL command forwarding enabled." -ForegroundColor Green
Write-Host "Commands not found in Windows will be automatically forwarded to WSL." -ForegroundColor Yellow
Write-Host "Use 'wslc <command> [args]' to manually forward commands to WSL." -ForegroundColor Cyan
