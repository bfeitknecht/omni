{ inputs, config, ... }:
let
  user = config.flake.username;
in
{
  # macOS settings for every darwin host: function only. Look and feel (Dock,
  # menu bar, appearance, Liquid Glass, window behaviour) stay at Apple's
  # defaults and are worked out one piece at a time; echo's full set is in
  # docs/MIGRATION.md section 1 to pick from.
  flake.modules.darwin.macos =
    { pkgs, ... }:
    {
      # sudo with Touch ID (also inside tmux and zellij: reattach)
      security.pam.services.sudo_local = {
        touchIdAuth = true;
        reattach = true;
      };

      system.defaults = {
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
