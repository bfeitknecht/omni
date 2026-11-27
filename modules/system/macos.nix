{ inputs, config, ... }:
let
  user = config.flake.username;
in
{
  # macOS settings for every darwin host. Function first; the look (menu
  # bar, appearance, Liquid Glass, window behaviour) is worked out one piece
  # at a time; echo's full set is in docs/MIGRATION.md section 1 to pick from.
  flake.modules.darwin.macos =
    { config, lib, ... }:
    {
      # sudo with Touch ID (also inside tmux and zellij: reattach)
      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };

      system.defaults = {
        # The Dock: hidden when not in use, and only these apps in this
        # order. macOS adds Finder first and Trash last; no folders, no
        # recent apps.
        dock = {
          autohide = true;
          show-recents = false;
          persistent-apps = [
            "/System/Applications/System Settings.app"
            "/Applications/Ghostty.app"
            "/Applications/Zed.app"
            "/Applications/Spotify.app"
          ];
          persistent-others = [ ];
        };

        # An empty desktop: no icons, no widgets, and a click on the
        # wallpaper does not move the windows away.
        WindowManager = {
          StandardHideDesktopIcons = true;
          HideDesktop = true;
          StandardHideWidgets = true;
          StageManagerHideWidgets = true;
          EnableStandardClickToShowDesktop = false;
        };

        # The lock screen without the large clock. Not verified on macOS 26
        # (the key is from Sonoma). If the clock stays: System Settings >
        # Wallpaper > Clock Appearance > Show large clock: Never.
        CustomSystemPreferences."/Library/Preferences/com.apple.loginwindow".UsesLargeDateTime = false;

        finder = {
          # Finder > Quit (Cmd-Q): a quit Finder leaves Cmd-Tab and the Dock
          # dot. Read at Finder start: after the first switch, log out once.
          QuitMenuItem = true;
          CreateDesktop = false; # Finder draws no desktop (no icons)
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

      # GUI apps (Zed and its agent servers, the Claude app) start from
      # launchd, not from a shell: give them the XDG locations of
      # features/home/xdg.nix and agents.nix too.
      launchd.user.envVariables = lib.getAttrs [
        "CLAUDE_CONFIG_DIR"
        "VIBE_HOME"
        "KUBECONFIG"
        "KUBECACHEDIR"
        "NPM_CONFIG_CACHE"
        "NPM_CONFIG_USERCONFIG"
      ] config.home-manager.users.${user}.home.sessionVariables;

      # The NULL wallpaper from apex brand/ (wallpaper.typ), light and dark,
      # in ~/Pictures/Wallpapers. install.sh sets it once (macOS has no
      # plain setting for it).
      home-manager.users.${user}.home.file = {
        "Pictures/Wallpapers/NULL-dark.png".source = "${inputs.apex}/brand/png/wallpaper-dark.png";
        "Pictures/Wallpapers/NULL-light.png".source = "${inputs.apex}/brand/png/wallpaper-light.png";
        "Pictures/Screenshots/.keep".text = "";
        # no "Last login: ..." line when a terminal opens (login(1) reads it)
        ".hushlogin".text = "";
      };
    };
}
