{ inputs, config, ... }:
let
  user = config.flake.username;
in
{
  # macOS settings for every darwin host: echo's settings as read on
  # 2026-11-19 (docs/MIGRATION.md section 1), the known-good baseline.
  # Keys under CustomUserPreferences have no typed option: a typo there fails
  # silently, the typed ones fail the eval.
  flake.modules.darwin.macos =
    { pkgs, ... }:
    {
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
          location = "/Users/${user}/Pictures/Screenshots";
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

        CustomUserPreferences = {
          NSGlobalDomain = {
            AppleMenuBarVisibleInFullscreen = true;
            # Liquid Glass (macOS 26+): the Appearance slider. Check after the
            # first switch: the key is right, the value is not verified.
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

      # The NULL wallpaper from apex brand/ (wallpaper.typ), light and dark,
      # in ~/Pictures/Wallpapers. `wallpaper` sets the one that matches the
      # appearance (macOS has no plain setting for it; the first run asks to
      # let the terminal control System Events).
      home-manager.users.${user} = {
        home.file = {
          "Pictures/Wallpapers/NULL-dark.png".source = "${inputs.apex}/brand/png/wallpaper-dark.png";
          "Pictures/Wallpapers/NULL-light.png".source = "${inputs.apex}/brand/png/wallpaper-light.png";
          "Pictures/Screenshots/.keep".text = "";
        };
        home.packages = [
          (pkgs.writeShellScriptBin "wallpaper" ''
            set -eu
            mode="''${1:-}"
            if [ -z "$mode" ]; then
              if defaults read -g AppleInterfaceStyle 2>/dev/null | grep -q Dark; then
                mode=dark
              else
                mode=light
              fi
            fi
            file="$HOME/Pictures/Wallpapers/NULL-$mode.png"
            # the store path behind the link: System Events wants a real file
            real="$(readlink -f "$file")"
            /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$real\""
          '')
        ];
      };
    };
}
