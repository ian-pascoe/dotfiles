{
  services = {
    displayManager.gdm = {
      enable = false;
      wayland = false;
    };
  };

  programs = {
    hyprland = {
      enable = false;
      xwayland.enable = false;
    };
  };
}
