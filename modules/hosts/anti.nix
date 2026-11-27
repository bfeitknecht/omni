{ inputs, config, ... }:
let
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.anti = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      { imports = [ config.flake.modules.darwin.default ]; }
      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        # all three macOS names (HostName sets LocalHostName too);
        # install.sh sets them before the first switch
        networking.hostName = "anti";
        networking.computerName = "anti";

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
            ## development
            "zed"
            "ghostty"
            "orbstack"
            "utm"
            ## security
            "tailscale-app"
            "proton-mail"
            "proton-pass"
            "protonvpn"
            # creating
            "obsidian"
            "prusaslicer"
            "audacity"
            ## communication
            "spotify"
            "whatsapp"
            "signal"
            "discord"
            ## rice
            # "dinky"
            # "tuna"
            # "kindavim"
            # "FelixKratz/sketchybar" # how to add tap?
            # "ukulele"
            # "hammerspoon"
            # "stats" # ?
          ];
        };
      }
    ];
  };
}
