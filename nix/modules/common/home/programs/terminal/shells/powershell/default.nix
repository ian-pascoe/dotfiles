{
  pkgs,
  config,
  dotfiles,
  ...
}:
{
  imports = [
    ../../../../../../util/home/dotfiles
  ];

  home = {
    packages = with pkgs; [
      powershell
    ];

    sessionPath = [
      "$HOME/.local/share/powershell/Scripts"
    ];
  };

  xdg.configFile = {
    "powershell/profile.ps1" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfiles.path}/Windows/PowerShell/profile.ps1";
      force = true;
    };
  };
}
