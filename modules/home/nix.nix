{ ... }: {
  flake.homeModules.nix =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = with pkgs; [
        any-nix-shell
        comma
        nix-output-monitor
      ];

      programs.nh = {
        enable = true;
        # the omni checkout convention; `nh darwin switch` / `nh os switch`
        # work bare from anywhere
        flake = "${config.home.homeDirectory}/.config/omni";
      };

      # lix everywhere: HM generates ~/.config/nix/nix.conf validated against
      # this package; the daemon side is owned by the hosts (nix.package) or
      # the lix installer (darwin, nix.enable = false)
      nix.package = lib.mkDefault (pkgs.lixPackageSets.stable.lix);
      nix.settings.extra-experimental-features = "nix-command flakes";

      # <nixpkgs> resolves through the flake registry — HM's default nixPath
      # points at per-user channels that don't exist in flakes-land (the
      # "Nix search path entry does not exist" warnings), and nix-index needs
      # a resolvable <nixpkgs> to build its database
      nix.registry.nixpkgs.to = {
        type = "github";
        owner = "NixOS";
        repo = "nixpkgs";
        ref = "nixos-unstable";
      };
      nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];
    };
}
