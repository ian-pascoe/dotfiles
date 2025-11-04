<#
.SYNOPSIS
Exports all valid (not expired) certificates from the LocalMachine Certificate Store to individual files and creates a CA bundle.
.DESCRIPTION
This script recursively scans the LocalMachine certificate store for all valid (not expired) X509 certificates and exports each certificate to an individual file in PEM format. The output files are named using the certificate's thumbprint and subject, ensuring uniqueness. Additionally, all certificates are concatenated into a single ca-bundle.crt file. The script also logs metadata about each certificate to the console. This script requires administrator privileges.
.PARAMETER OutputDir
Specifies the directory where the exported certificate files will be saved. Defaults to a temporary directory.
.PARAMETER CertExtension
CertExtension
Specifies the file extension for the exported certificate files. Defaults to "pem". Use "crt" for usage on Windows systems.
.PARAMETER InsertLineBreaks
Specifies whether to insert line breaks in the Base64 encoded certificate data. Defaults to $true.
.EXAMPLE
.\Get-AllCertificates.ps1 -OutputDir "C:\Certificates" -CertExtension "crt" -InsertLineBreaks $false
Exports all valid certificates from LocalMachine store to the specified directory with .crt extension without line breaks in the Base64 data.
.NOTES
Requires administrator privileges to access the LocalMachine certificate store.
#>
#Requires -RunAsAdministrator
param(
  [string]$OutputDir="$env:TEMP\AllCertificates",
  [string]$CertExtension="pem",# use "crt" for usage on windows systems
  [bool]$InsertLineBreaks=$true
)

If (Test-Path $OutputDir) {
  Remove-Item $OutputDir -Recurse -Force
}
New-Item $OutputDir -ItemType directory

# Initialize CA bundle file
$caBundlePath = "{0}\ca-bundle.crt" -f $OutputDir
if (Test-Path $caBundlePath) {
  Remove-Item $caBundlePath -Force
}

# Get all certificates from LocalMachine store
Get-ChildItem -Recurse -Path Cert:\LocalMachine `
| Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2] -and $_.NotAfter.Date -gt (Get-Date).Date } `
| ForEach-Object {

  # Write Cert Info (ex. for CSV holding Meta Data); Log Info having full names and additional values for reference
  Write-Output "$($_.Thumbprint);$($_.GetSerialNumberString());$($_.Archived);$($_.GetExpirationDateString());$($_.EnhancedKeyUsageList);$($_.GetName())"

  # append "Thumbprint" of Cert for unique file names
  $name = "$($_.Thumbprint)--$($_.Subject)" -replace '[\W]', '_'
  $max = $name.Length

  # reduce length to prevent filesystem errors
  if ($max -gt 150) {
    $max = 150 
  }
  $name = $name.Substring(0, $max)

  # build path
  $path = "{0}\{1}.{2}" -f $OutputDir,$name,$CertExtension
  if (Test-Path $path) {
    Write-Output "Skipping existing cert file: $path"
    continue 
  } # next if cert was already written

  $oPem=new-object System.Text.StringBuilder
  [void]$oPem.AppendLine("-----BEGIN CERTIFICATE-----")
  [void]$oPem.AppendLine([System.Convert]::ToBase64String($_.RawData,$InsertLineBreaks ? 1 : 0))
  [void]$oPem.AppendLine("-----END CERTIFICATE-----")

  $pemContent = $oPem.toString()
  $pemContent | add-content $path
  
  # Append to CA bundle with a comment header
  Add-Content -Path $caBundlePath -Value "# Subject: $($_.Subject)"
  Add-Content -Path $caBundlePath -Value "# Issuer: $($_.Issuer)"
  Add-Content -Path $caBundlePath -Value "# Thumbprint: $($_.Thumbprint)"
  Add-Content -Path $caBundlePath -Value $pemContent
}

Write-Output "`nCA bundle created at: $caBundlePath"
