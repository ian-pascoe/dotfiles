{ lib, ... }:
let
  zd = ''
    zd() {
      if [ $# -eq 0 ]; then
        builtin cd ~ && zoxide add "$(pwd)" && return
      elif [ -d "$1" ]; then
        builtin cd "$1" && zoxide add "$(pwd)" && return
      else
        z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
      fi
    }
  '';
in
{
  programs = {
    zoxide.enable = lib.mkDefault true;
    bash.initExtra = zd;
    zsh.initContent = lib.mkOrder 1000 zd;
  };

  home.shellAliases = {
    cd = "zd";
  };
}
