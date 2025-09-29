{
  system.defaults.dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 1.0;
    mineffect = "scale";
    minimize-to-application = true;
    mouse-over-hilite-stack = true;
    mru-spaces = false;
    orientation = "bottom";
    show-process-indicators = true;
    show-recents = false;
    showhidden = false;
    static-only = false;
    tilesize = 50;
    # Hot corners
    # Possible values:
    #  0: no-op
    #  2: Mission Control
    #  3: Show application windows
    #  4: Desktop
    #  5: Start screen saver
    #  6: Disable screen saver
    #  7: Dashboard
    # 10: Put display to sleep
    # 11: Launchpad
    # 12: Notification Center
    # 13: Lock Screen
    # 14: Quick Notes
    wvous-tl-corner = 0;
    wvous-tr-corner = 0;
    wvous-bl-corner = 0;
    wvous-br-corner = 0;
    persistent-apps = [
      {
        app = "/System/Applications/System Settings.app";
      }
      {
        app = "/System/Applications/Apps.app";
      }
      {
        spacer = {
          small = true;
        };
      }
      {
        app = "/Applications/Helium.app";
      }
      {
        app = "/System/Applications/Messages.app";
      }
      {
        app = "/System/Applications/FaceTime.app";
      }
      {
        app = "/Applications/Ghostty.app";
      }
      {
        app = "/System/Applications/Notes.app";
      }
    ];
  };
}
