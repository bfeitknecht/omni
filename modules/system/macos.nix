{ inputs, config, ... }:
let
  user = config.flake.username;
in
{
  # macOS settings for every darwin host: function only. Look and feel (menu
  # bar, appearance, Liquid Glass, window behaviour, the Dock apart from
  # autohide) stay at Apple's defaults and are worked out one piece at a
  # time; echo's full set is in docs/MIGRATION.md section 1 to pick from.
  flake.modules.darwin.macos =
    { ... }:
    {
      # sudo with Touch ID (also inside tmux and zellij: reattach)
      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };

      system.defaults = {
        # the one Dock change: hide it when not in use
        dock.autohide = true;

        finder = {
          QuitMenuItem = true; # Finder > Quit (Cmd-Q)
          ShowPathbar = true;
          FXDefaultSearchScope = "SCcf"; # search the current folder
          FXEnableExtensionChangeWarning = false;
          NewWindowTarget = "Home";
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
        };

        NSGlobalDomain = {
          AppleShowAllExtensions = true;
          # typing: no autocorrect, no smart capitals, no double-space period
          NSAutomaticCapitalizationEnabled = false;
          NSAutomaticSpellingCorrectionEnabled = false;
          NSAutomaticPeriodSubstitutionEnabled = false;
          NSAutomaticInlinePredictionEnabled = false;
        };
      };

      # The NULL wallpaper from apex brand/ (wallpaper.typ), light and dark,
      # in ~/Pictures/Wallpapers. install.sh sets it once (macOS has no
      # plain setting for it).
      home-manager.users.${user}.home.file = {
        "Pictures/Wallpapers/NULL-dark.png".source = "${inputs.apex}/brand/png/wallpaper-dark.png";
        "Pictures/Wallpapers/NULL-light.png".source = "${inputs.apex}/brand/png/wallpaper-light.png";
        "Pictures/Screenshots/.keep".text = "";
      };
    };
}
