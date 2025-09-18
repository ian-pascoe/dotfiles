# Imports
Import-Module PSReadLine
Import-Module Terminal-Icons

# Starship
Invoke-Expression (&starship init powershell)

# Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# Scoop search
. ([ScriptBlock]::Create((& scoop-search --hook | Out-String)))

# Aliases
Set-Alias -Name ls -Value lsd
Set-Alias -Name cat -Value bat
Set-Alias -Name cd -Value z -Option AllScope
Set-Alias -Name find -Value fd

function ll {
  lsd -la $args
}
Set-Alias -Name ll -Value ll

function lla {
  lsd -la $args
}
Set-Alias -Name lla -Value lla

function Make-Link ($target, $link) {
  New-Item -Path $link -ItemType SymbolicLink -Value $target
}
