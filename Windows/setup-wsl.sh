#!/bin/bash

windowsHome="$1"
dotfilesDir="$2"
sslCertBundle="$3"
if [ -z "$windowsHome" ] || [ -z "$dotfilesDir" ] || [ -z "$sslCertBundle" ]; then
	echo "Usage: $0 <windows-home> <dotfiles-directory> <ssl-cert-bundle-path>"
	exit 1
fi

echo "Setting up WSL environment..."
echo "Dotfiles Directory: $dotfilesDir"
echo "SSL Certificate Bundle: $sslCertBundle"
export http_proxy="$HTTP_PROXY"

export HTTPS_PROXY="$HTTP_PROXY"
export https_proxy="$HTTP_PROXY"

export ALL_PROXY="$HTTP_PROXY"
export all_proxy="$HTTP_PROXY"

export NIX_SSL_CERT_FILE="$sslCertBundle"

echo "Creating symlink for dotfiles..."
ln -snf "$windowsHome" $HOME/.windows
ln -snf "$dotfilesDir" $HOME/.dotfiles
ln -snf "$dotfilesDir/nix" $HOME/.nix

echo "Building NixOS configuration for WSL..."
sudo -HE nixos-rebuild switch --flake $HOME/.nix#Work-WSL --impure
