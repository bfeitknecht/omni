# the MacBooks: auto (the current one, after its reset) and anti (the new
# MacBook Pro). One file, because flake.darwinConfigurations has no merge
# option: a second file defining it fails the eval.
{
  inputs,
  config,
  lib,
  ...
}:
let
  mkMacbook =
    name:
    inputs.nix-darwin.lib.darwinSystem {
      modules = [
        { nixpkgs.hostPlatform = "aarch64-darwin"; }
        {
          imports = with config.flake.modules.darwin; [
            default
            macbook
          ];
        }
        { networking.hostName = name; }
      ];
    };
in
{
  flake.darwinConfigurations = lib.genAttrs [
    "auto"
    "anti"
  ] mkMacbook;
}
