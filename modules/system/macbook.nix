{ inputs, config, ... }: {
  # what every MacBook shares on top of the darwin class: Homebrew (owned by
  # nix-homebrew) and the macOS settings. Hosts (auto, anti) add a hostname.
  # The settings are read from the old MacBook (echo) on 2026-11-19 with
  # `defaults read`.
  flake.modules.darwin.macbook = { ... }: {
    imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

    # nix-darwin installs and owns Homebrew itself;
    # the homebrew block below manages only what the Brewfile lists
    nix-homebrew = {
      enable = true;
      user = config.flake.username;
    };

    homebrew = {
      enable = true;
      onActivation.cleanup = "zap";
      casks = [
        "zed"
        "ghostty"
        # "spotify"
        # "whatsapp"
        # "signal"
        # "orbstack"
        # "prusaslicer"
        # "stats"
        # "raycast"
        # "proton-mail"
        # "proton-pass"
        # "proton-vpn"
        # "audacity"
        # "obsidian"
        # "utm"
      ];
    };

    system.defaults = {
      dock = {
        autohide = true;
        autohide-delay = 0.0;
        autohide-time-modifier = 0.15;
        orientation = "left";
        tilesize = 42;
        magnification = false;
        mineffect = "genie";
        minimize-to-application = false;
        show-recents = false;
        show-process-indicators = true;
        # hot corners: top right Quick Note, bottom right app windows
        wvous-tr-corner = 14;
        wvous-br-corner = 3;
      };

      finder = {
        QuitMenuItem = true;
        ShowPathbar = true;
        ShowStatusBar = false;
        FXPreferredViewStyle = "Nlsv"; # list view
        FXDefaultSearchScope = "SCcf"; # search the current folder
        FXEnableExtensionChangeWarning = false;
        NewWindowTarget = "Home";
        ShowExternalHardDrivesOnDesktop = true;
        ShowHardDrivesOnDesktop = false;
        ShowRemovableMediaOnDesktop = true;
        ShowMountedServersOnDesktop = true;
      };

      WindowManager = {
        GloballyEnabled = false; # Stage Manager off
        AutoHide = true;
        HideDesktop = true;
        EnableTiledWindowMargins = false;
        EnableTopTilingByEdgeDrag = false;
        StageManagerHideWidgets = false;
        StandardHideWidgets = false;
      };

      screencapture = {
        target = "clipboard";
        disable-shadow = true;
        include-date = true;
        show-thumbnail = false;
        location = "~/Pictures/Screenshots";
      };

      trackpad = {
        Clicking = true; # tap to click
        TrackpadRightClick = true;
        TrackpadThreeFingerDrag = false;
        Dragging = false;
        ActuateDetents = true;
        FirstClickThreshold = 1;
        SecondClickThreshold = 1;
      };

      menuExtraClock = {
        ShowAMPM = true;
        ShowDate = 1;
        ShowDayOfWeek = true;
        ShowSeconds = true;
        IsAnalog = false;
      };

      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark";
        AppleShowAllExtensions = true;
        AppleKeyboardUIMode = 0;
        AppleWindowTabbingMode = "always";
        AppleSpacesSwitchOnActivate = true;
        AppleEnableSwipeNavigateWithScrolls = true;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticPeriodSubstitutionEnabled = false;
        NSAutomaticInlinePredictionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSTableViewDefaultSizeMode = 2;
        _HIHideMenuBar = false;
        "com.apple.swipescrolldirection" = true;
        "com.apple.trackpad.scaling" = 1.0;
        "com.apple.sound.beep.feedback" = 1;
      };

      # keys nix-darwin has no typed option for
      CustomUserPreferences = {
        NSGlobalDomain = {
          AppleMenuBarVisibleInFullscreen = true;
          # Liquid Glass (macOS 26+): the Appearance slider
          NSGlassDiffusionSetting = 1;
          AppleReduceDesktopTinting = true;
          SLSMenuBarUseBlurredAppearance = true;
          NSCloseAlwaysConfirmsChanges = true;
          NSQuitAlwaysKeepsWindows = true;
          AppleActionOnDoubleClick = "None";
        };
        "com.apple.WindowManager".AppWindowGroupingBehavior = 1;
        "com.apple.controlcenter".AutoHideMenuBarOption = 3;
      };
    };
  };
}
