{ ... }: {
  flake.homeModules.nix = { config, lib, pkgs, ... }: {
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
  };
}
