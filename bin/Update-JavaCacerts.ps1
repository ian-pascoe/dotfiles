<#
.SYNOPSIS
    Sync Windows certificates into Java's cacerts truststore.
.DESCRIPTION
    This script exports all certificates from the Windows Certificate Store (LocalMachine)
    and imports them into the Java cacerts truststore using keytool.
.PARAMETER JavaHome
    The path to the Java installation directory. Defaults to the JAVA_HOME environment variable.
.PARAMETER StorePass
    The password for the Java cacerts truststore. Defaults to "changeit".
.NOTES
    Requires administrator privileges to access the LocalMachine certificate store.
#>
#Requires -RunAsAdministrator

param(
  [string]$JavaHome = $env:JAVA_HOME,
  [string]$StorePass = "changeit"
)

if (-not $JavaHome) {
  Write-Error "JAVA_HOME is not set."; exit 1 
}

$Keytool = Join-Path $JavaHome "bin\keytool.exe"
$Cacerts = Join-Path $JavaHome "lib\security\cacerts"
if (-not (Test-Path $Keytool)) {
  Write-Error "keytool not found: $Keytool"; exit 1 
}
if (-not (Test-Path $Cacerts)) {
  Write-Error "cacerts not found: $Cacerts"; exit 1 
}

$TempDir = Join-Path $env:TEMP "java-trust-sync"
$RootsDir = Join-Path $TempDir "roots"
New-Item -ItemType Directory -Force -Path $RootsDir | Out-Null

Write-Host "Exporting all certificates from Cert:\LocalMachine ..."
$exported = 0

# Get all certificates from all LocalMachine stores
$certs = Get-ChildItem -Recurse -Path Cert:\LocalMachine | 
  Where-Object { $_ -is [System.Security.Cryptography.X509Certificates.X509Certificate2] }

foreach ($cert in $certs) {
  $file = Join-Path $RootsDir ($cert.Thumbprint + ".cer")
  # Skip if already exported (handles duplicates across stores)
  if (Test-Path $file) {
    Write-Host "Skipping duplicate cert: $($cert.Thumbprint)"
    continue
  }
  Export-Certificate -Cert $cert -FilePath $file -Force | Out-Null
  $exported++
}

Write-Host "Exported $exported certificates total."

# Get current aliases in cacerts to prevent duplicates
Write-Host "Scanning existing Java truststore..."
$existing = & $Keytool -list -keystore $Cacerts -storepass $StorePass 2>$null | 
  Select-String "trustedCertEntry" | 
  ForEach-Object { ($_ -split ",")[0].Trim() }

Write-Host "Found $($existing.Count) existing certs."

# Import new certs only if not already in cacerts
$imported = 0
foreach ($certFile in Get-ChildItem $RootsDir -Filter *.cer) {
  $alias = $certFile.BaseName
  if ($existing -contains $alias) {
    Write-Host "Certificate already exists in cacerts: $alias"
    continue 
  }

  & $Keytool -importcert -trustcacerts -noprompt `
    -alias $alias `
    -file $certFile.FullName `
    -keystore $Cacerts `
    -storepass $StorePass 2>$null

  $imported++
}

Write-Host "Imported $imported new certificates into $Cacerts."

Remove-Item $TempDir -Recurse -Force
Write-Host "Done."
