# Imports
Import-Module PSReadLine
Import-Module Terminal-Icons

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Aliases
Set-Alias -Name ls -Value lsd
Set-Alias -Name cat -Value bat
Set-Alias -Name cd -Value z -Option AllScope
Set-Alias -Name find -Value fd

function Make-Link ($target, $link) {
    New-Item -Path $link -ItemType SymbolicLink -Value $target
}
