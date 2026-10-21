# modules/flake/homes.nix — standalone home-manager configurations, one per
# OS host, derived (not declared): `nh home switch` auto-detects bf@<host>.
{
  inputs,
  config,
  lib,
  ...
}:
let
  user = config.flake.username;

  mkHome =
    system:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${system}.extend config.flake.overlays.lix;
      modules = [
        config.flake.modules.homeManager.default
        ({ pkgs, ... }: {
          home.username = user;
          # OS home convention, decided by the platform predicate — no string matching
          home.homeDirectory =
            if pkgs.stdenv.hostPlatform.isDarwin then "/Users/${user}" else "/home/${user}";
        })
      ];
    };
in
{
  # lazy on purpose — the host configs are forced at output-read time
  # (nh, nix flake check), never during the flake-parts merge
  flake.homeConfigurations = lib.mapAttrs' (
    host: cfg: lib.nameValuePair "${user}@${host}" (mkHome cfg.pkgs.system)
  ) (config.flake.nixosConfigurations // config.flake.darwinConfigurations);
}
