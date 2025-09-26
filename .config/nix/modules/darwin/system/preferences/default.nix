{
  system.defaults = {
    CustomSystemPreferences = {
      finder = {
        DisableAllAnimations = true;
        FXEnableExtensionChangeWarning = false;
        QuitMenuItem = true;
        ShowExternalHardDrivesOnDesktop = false;
        ShowHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowPathbar = true;
        ShowRemovableMediaOnDesktop = false;
        _FXSortFoldersFirst = true;
      };

      NSGlobalDomain = {
        AppleAccentColor = 1;
        AppleHighlightColor = "0.65098 0.85490 0.58431";
        AppleSpacesSwitchOnActivate = false;
        WebKitDeveloperExtras = true;
        com.apple.swipescrolldirection = false;
        KeyRepeat = 1;
        AppleShowAllExtensions = true;
        _HIHideMenuBar = true;
      };
    };

    CustomUserPreferences = {
      "com.apple.SoftwareUpdate" = {
        AutomaticCheckEnabled = true;
        AutomaticDownload = 1;
        CriticalUpdateInstall = 1;
        ScheduleFrequency = 1;
      };
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = true;
      FXDefaultSearchScope = "SCcf";
      FXEnableExtensionChangeWarning = false;
      # NOTE: Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
      FXPreferredViewStyle = "Nlsv";
      QuitMenuItem = true;
      ShowStatusBar = false;
      _FXShowPosixPathInTitle = true;
    };

    # login window settings
    loginwindow = {
      # disable guest account
      GuestEnabled = false;
      # show name instead of username
      SHOWFULLNAME = false;
    };

    menuExtraClock = {
      ShowAMPM = true;
      ShowDate = 1;
      ShowDayOfWeek = true;
      ShowSeconds = true;
    };

    NSGlobalDomain = {
      "com.apple.sound.beep.feedback" = 0;
      "com.apple.sound.beep.volume" = 0.0;
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Automatic";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticWindowAnimationsEnabled = false;
      _HIHideMenuBar = true;
    };

    spaces = {
      spans-displays = false;
    };

    universalaccess = {
      reduceMotion = false;
    };
  };
}
