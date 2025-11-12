<#
.SYNOPSIS
  Configures environment proxy settings based on Windows Internet Settings.
.DESCRIPTION 
  Reads the current user's Internet Settings from the registry and sets
  the corresponding environment variables (HTTP_PROXY, HTTPS_PROXY, etc.)
  for use by command-line tools and applications.
#>

# Get Windows Internet Settings
$internetSettings = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'

$HttpProxy  = $null
$HttpsProxy = $null
$FtpProxy   = $null
$AllProxy   = $null
$NoProxy    = $null

if ($internetSettings.ProxyEnable -eq 1 -and $internetSettings.ProxyServer) {
  # Manual proxy configuration
  $proxy = $internetSettings.ProxyServer

  # ProxyServer can look like:
  #   "proxy.company.com:8080"
  #   "http=proxy1:8080;https=proxy2:8443;ftp=proxy3:21"
  # We normalize to HTTP(S)_PROXY variables.

  $pairs = $proxy -split ';'
  foreach ($p in $pairs) {
    if ($p -match '^(http|https|ftp)=(.+)$') {
      $proto, $addr = $matches[1], $matches[2]
      switch ($proto) {
        'http'  {
          $HttpProxy  = "http://$addr" 
        }
        'https' {
          $HttpsProxy = "http://$addr" 
        }
        'ftp'   {
          $FtpProxy   = "http://$addr"
        }
      }
    } else {
      # Single proxy for all protocols
      $HttpProxy  = "http://$p"
      $HttpsProxy = "http://$p"
      $FtpProxy   = "http://$p"
      $AllProxy   = "http://$p"
    }
  }

  # Optional: Exclusion list
  if ($internetSettings.ProxyOverride) {
    $NoProxy = ($internetSettings.ProxyOverride -replace ';', ',')
  }

} elseif ($internetSettings.AutoConfigURL) {
  # PAC / WPAD configuration (e.g., Zscaler)
  Write-Log -Level Info -Message "PAC file detected at: $($internetSettings.AutoConfigURL)"
  
  # Extract hostname and port from PAC URL (strip the path)
  $pacUri = [System.Uri]$internetSettings.AutoConfigURL
  $proxyAddress = "$($pacUri.Scheme)://$($pacUri.Host)"
  if ($pacUri.Port -ne -1) {
    $proxyAddress += ":$($pacUri.Port)"
  }
  
  $HttpProxy  = $proxyAddress
  $HttpsProxy = $proxyAddress
  $FtpProxy   = $proxyAddress
  $AllProxy   = $proxyAddress
}

Set-EnvironmentVariable -Name HTTP_PROXY -Value $HttpProxy -Scope User
Set-EnvironmentVariable -Name HTTPS_PROXY -Value $HttpsProxy -Scope User
Set-EnvironmentVariable -Name ALL_PROXY -Value $AllProxy -Scope User
Set-EnvironmentVariable -Name FTP_PROXY -Value $FtpProxy -Scope User
Set-EnvironmentVariable -Name NO_PROXY -Value $NoProxy -Scope User
