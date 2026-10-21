{ inputs, config, ... }:
let
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.auto = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      { imports = [ config.flake.modules.darwin.default ]; }
      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        networking.hostName = "auto";

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
      }
    ];
  };
}
