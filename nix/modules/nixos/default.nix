{
  imports = [
    ./libraries
    ./programs
    ./services
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.05";
}
