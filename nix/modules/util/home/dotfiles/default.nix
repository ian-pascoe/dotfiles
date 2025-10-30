{
  config,
  lib,
  ...
}:
let
  dotfilesPath = "${config.home.homeDirectory}/.dotfiles";
  dotfilesRepo = "https://github.com/ian-pascoe/dotfiles.git";
in
{
  home =
    let
      git = config.programs.git.package;
    in
    {
      activation = {
        "setupDotfiles" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          echo "Setting up dotfiles"
          if [ -d "${dotfilesPath}/.git" ]; then
            (cd "${dotfilesPath}" && ${git}/bin/git pull --ff-only)
          else
            ${git}/bin/git clone "${dotfilesRepo}" "${dotfilesPath}"
          fi
        '';
      };
      file = {
        ".nix" = {
          source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/nix";
          force = true;
        };
      };
    };

  _module.args.dotfiles = {
    path = dotfilesPath;
    repo = dotfilesRepo;
  };
}
