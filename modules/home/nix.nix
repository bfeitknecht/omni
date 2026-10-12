{ ... }: {
  flake.homeModules.nix = { lib, pkgs, ... }: {
    home.packages = with pkgs; [
      any-nix-shell
      comma
      nh
      nix-output-monitor
    ];

    # lix everywhere: HM generates ~/.config/nix/nix.conf validated against
    # this package. mkDefault so the OS integration's forward (the system
    # nix.package) wins where one exists; on darwin (nix.enable = false)
    # this is the only definition.
    nix.package = lib.mkDefault (pkgs.lixPackageSets.stable.lix);
    nix.settings.extra-experimental-features = "nix-command flakes";
  };
}
