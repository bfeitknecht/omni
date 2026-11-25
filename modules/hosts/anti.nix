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
        networking.hostName = "anti";

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
            # development
            "zed"
            "ghostty"
            "orbstack"
            "utm"
            # security
            "tailscale-app" # the tailnet: devil, the cluster, kubectl
            "proton-mail"
            "proton-pass"
            "proton-vpn"
            # creating
            "obsidian"
            "prusaslicer"
            "audacity"
            # communication
            "spotify"
            "whatsapp"
            "signal"
            "discord"
            # rice
            # need stats and raycast?
            # what WM? yabai, aerospace, dinky
            # what launcher? raycast, tuna
            # "kindavim"
            # "FelixKratz/borders" # jankyborders
            # "FelixKratz/sketchybar" # how to add tap?
            # "stats"
            # how to do keyboard remaps and stuff (currently karabiner)
          ];
        };
      }
    ];
  };
}
