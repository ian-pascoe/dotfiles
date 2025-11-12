#!/usr/bin/env bash

if [ "$(whoami)" != "root" ]; then
  echo "This script must be run as root. Please run with sudo."
  exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Error handler
error_exit() {
  log_error "$1"
  exit 1
}

# Validate arguments
windowsUsername="$1"
windowsHome="$2"
dotfilesRepoPath="$3"
sslCertBundle="$4"

if [ -z "$windowsUsername" ] || [ -z "$windowsHome" ] || [ -z "$dotfilesRepoPath" ] || [ -z "$sslCertBundle" ]; then
  log_error "Missing required arguments"
  echo "Usage: $0 <username> <windows-home> <dotfiles-directory> <ssl-cert-bundle-path>"
  exit 1
fi

log_info "Setting up WSL environment..."
log_info "Windows Home: $windowsHome"
log_info "dotfiles Repo Directory: $dotfilesRepoPath"
log_info "SSL Certificate Bundle: $sslCertBundle"

# Validate paths exist
if [ ! -d "$windowsHome" ]; then
  error_exit "Windows home directory does not exist: $windowsHome"
fi

if [ ! -d "$dotfilesRepoPath" ]; then
  error_exit "dotfiles repo directory does not exist: $dotfilesRepoPath"
fi

if [ ! -f "$sslCertBundle" ]; then
  error_exit "SSL certificate bundle file does not exist: $sslCertBundle"
fi

if [ ! -d "$dotfilesRepoPath/nix" ]; then
  error_exit "Nix configuration directory does not exist: $dotfilesRepoPath/nix"
fi

# Check if a user with UID 1000 exists and delete it
EXISTING_USER=$(getent passwd 1000 | cut -d: -f1)
if [ -n "$EXISTING_USER" ] && [ "$windowsUsername" != "$EXISTING_USER" ]; then
  log_warning "Deleting existing user with UID 1000: $EXISTING_USER"
  pkill -u "$EXISTING_USER" 2>/dev/null || true
  userdel -rf "$EXISTING_USER" 2>/dev/null || true
fi

# Create the user and home directory
newUserHome="/home/$windowsUsername"
if ! id -u "$windowsUsername" &>/dev/null; then
  log_info "Creating user: $windowsUsername"
  useradd -m -d "$newUserHome" "$windowsUsername" || error_exit "Failed to create user: $windowsUsername"
  log_success "User $windowsUsername created successfully"
else
  newUserHome=$(eval echo "~$windowsUsername")
  log_info "User $windowsUsername already exists"
fi

export NIX_DEFAULT_USER="$windowsUsername"

# Set up proxy environment variables
log_info "Configuring proxy settings..."
export http_proxy="$HTTP_PROXY"
export HTTPS_PROXY="$HTTP_PROXY"
export https_proxy="$HTTP_PROXY"
export ALL_PROXY="$HTTP_PROXY"
export all_proxy="$HTTP_PROXY"
export NIX_SSL_CERT_FILE="$sslCertBundle"
log_success "Proxy settings configured"

# Function to create or update symlink
create_symlink() {
  local target="$1"
  local link_name="$2"
  local description="$3"

  # Check if symlink already exists and points to correct target
  if [ -L "$link_name" ]; then
    local current_target=$(readlink -f "$link_name" 2>/dev/null || echo "")
    local new_target=$(readlink -f "$target" 2>/dev/null || echo "$target")

    if [ "$current_target" = "$new_target" ]; then
      log_info "$description symlink already up to date: $link_name -> $target"
      return 0
    else
      log_warning "$description symlink exists but points to wrong target, updating..."
    fi
  elif [ -e "$link_name" ]; then
    log_warning "$description exists but is not a symlink, backing up..."
    mv "$link_name" "${link_name}.backup.$(date +%Y%m%d_%H%M%S)" || error_exit "Failed to backup $link_name"
  fi

  log_info "Creating $description symlink: $link_name -> $target"
  ln -snf "$target" "$link_name" || error_exit "Failed to create symlink: $link_name"
  log_success "$description symlink created successfully"
}

# Create symlinks
log_info "Setting up symlinks..."
create_symlink "$dotfilesRepoPath" "$newUserHome/.dotfiles" "dotfiles Repo"
create_symlink "$dotfilesRepoPath/nix" "$newUserHome/.nix" "Nix configuration"
log_success "All symlinks configured"

chown -RL "$windowsUsername":users "$newUserHome/.dotfiles/"
chmod -RL 774 "$newUserHome/.dotfiles/"

chown -RL "$windowsUsername":users "$newUserHome/.nix/"
chmod -RL 774 "$newUserHome/.nix/"
log_success "Ownership of symlinked directories set to '$windowsUsername:users'"

# Build NixOS configuration
log_info "Building NixOS configuration for WSL..."
log_info "This may take several minutes..."

if ! command -v nixos-rebuild &>/dev/null; then
  error_exit "nixos-rebuild command not found. Is NixOS installed in WSL?"
fi

# make dotfiles repo safe for root
cat <<EOF >/root/.gitconfig
[safe]
  directory = "${dotfilesRepoPath%/}"
EOF

# Run nixos-rebuild with error handling
if nixos-rebuild switch --flake "$newUserHome/.nix#Work-WSL" --impure; then
  log_success "NixOS configuration built successfully"
else
  error_exit "Failed to build NixOS configuration (exit code: $?)"
fi

log_success "WSL environment setup completed successfully!"
