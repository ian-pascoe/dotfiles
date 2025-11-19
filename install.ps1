<#
.SYNOPSIS
    Bootstrap installer for dotfiles
.DESCRIPTION
    Downloads and executes the dotfiles setup script from GitHub.
#>

[CmdletBinding()]
param(
  [string]$Branch = "master"
)

$ErrorActionPreference = 'Stop'

# Configuration
$RepoOwner = "ian-pascoe"
$RepoName = "dotfiles"
$GitHubBaseUrl = "https://github.com"

Write-Host "=== Dotfiles Installation ===" -ForegroundColor Cyan
Write-Host "Downloading dotfiles from GitHub..." -ForegroundColor Cyan

# Create temporary directory
$TempDir = Join-Path $env:TEMP "dotfiles-$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
  Write-Host "Downloading repository archive..." -ForegroundColor Cyan
  
  # Download repository as zip archive
  $ZipUrl = "$GitHubBaseUrl/$RepoOwner/$RepoName/archive/refs/heads/$Branch.zip"
  $ZipPath = Join-Path $TempDir "repo.zip"
  
  try {
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -ErrorAction Stop
  } catch {
    Write-Error "Failed to download repository from $ZipUrl. Check your internet connection and that the repository/branch exist and are public."
    exit 1
  }
      
  Write-Host "Extracting files..." -ForegroundColor Cyan
    
  # Extract the zip file
  $ExtractPath = Join-Path $env:TEMP "dotfiles"
  if (Test-Path $ExtractPath) {
    Remove-Item -Path $ExtractPath -Recurse -Force
  }
  Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

  # Find the extracted folder (GitHub creates a folder with repo name and commit hash)
  $RepoFolder = Get-ChildItem -Path $ExtractPath -Directory | Select-Object -First 1
  if (-not $RepoFolder) {
    Write-Error "Failed to find extracted repository folder."
    exit 1
  }

  $DotfilesPath = Join-Path $env:USERPROFILE ".dotfiles"
  if (Test-Path $DotfilesPath) {
    throw "Dotfiles directory already exists at $DotfilesPath. Just run the setup script from there."
  }
  Copy-Item -Path $RepoFolder.FullName -Destination $DotfilesPath -Recurse -Force
    
  # Check if setup.ps1 exists
  $SetupScript = Join-Path $DotfilesPath "Windows\setup.ps1"
  if (-not (Test-Path $SetupScript)) {
    Write-Error "Setup script not found at expected location: $SetupScript"
    exit 1
  }
    
  Write-Host "Running setup script..." -ForegroundColor Cyan
    
  # Execute the setup script
  & $SetupScript
    
  Write-Host "Installation complete!" -ForegroundColor Green
} catch {
  Write-Error "Installation failed: $_"
  exit 1
} finally {
  # Clean up temporary files
  Write-Host "Cleaning up temporary files..." -ForegroundColor Gray
    
  # Remove temporary directory
  if (Test-Path $TempDir) {
    Remove-Item -Path $TempDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
