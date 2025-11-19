{ lib, ... }:
{
  # Find all default.nix files in a directory recursively
  # Returns a list of paths that can be used in imports
  findModules =
    let
      # Recursive function to find modules
      findModulesRec =
        path:
        let
          # Read directory contents
          entries = builtins.readDir path;

          # Process each entry
          processEntry =
            name: type:
            let
              fullPath = path + "/${name}";
            in
            if type == "directory" then
              # Recursively search subdirectories
              findModulesRec fullPath
            else if type == "regular" && name == "default.nix" then
              # Found a module file
              [ fullPath ]
            else
              [ ];

          # Collect all modules from all entries
          allModules = lib.flatten (lib.mapAttrsToList processEntry entries);
        in
        allModules;
    in
    findModulesRec;
}
