{ inputs, config, ... }: {
  # standalone home-manager configurations — the class tree without an OS
  # underneath. Named user@host so `nh home switch` auto-detects them.
  flake.homeConfigurations = {
    "bf@auto" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin.extend config.flake.overlays.lix;
      modules = [
        config.flake.homeModules.default
        {
          home.username = config.flake.username;
          home.homeDirectory = "/Users/${config.flake.username}";
        }
      ];
    };

    "bf@vm" = inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.aarch64-linux.extend config.flake.overlays.lix;
      modules = [
        config.flake.homeModules.default
        {
          home.username = config.flake.username;
          home.homeDirectory = "/home/${config.flake.username}";
        }
      ];
    };
  };
}
