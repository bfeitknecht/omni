{ inputs, config, ... }: {
  flake.darwinConfigurations.auto = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      { nixpkgs.hostPlatform = "aarch64-darwin"; }
      { nixpkgs.overlays = [ config.flake.overlays.lix ]; }
      inputs.home-manager.darwinModules.home-manager
      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${config.flake.username}.imports = [
          config.flake.homeModules.default
        ];
      }
      {
        networking.hostName = "auto";
        system.primaryUser = config.flake.username;
        users.users.${config.flake.username}.home = "/Users/${config.flake.username}";
        system.stateVersion = 7;

        # the lix installer owns the daemon and /etc/nix/nix.conf
        nix.enable = false;

        # nix-darwin installs and owns Homebrew itself; the homebrew block
        # below manages only what the Brewfile lists
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
