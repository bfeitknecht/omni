{ inputs, config, ... }: {
  # the shared NixOS class — everything every NixOS host (devil, vm) shares.
  # hosts (modules/hosts/) add only host-specific bits on top. No platform
  # here — each host declares its own nixpkgs.hostPlatform.
  flake.modules.nixos.default = { pkgs, ... }: {
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    nixpkgs.overlays = [ config.flake.overlays.lix ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${config.flake.username}.imports = [
        config.flake.modules.homeManager.default
      ];
    };

    time.timeZone = "Europe/Zurich";
    system.stateVersion = "26.11";

    # lix is the system nix (the nixpkgs default is upstream nix);
    # root/sudo nix (nh os switch) reads /etc/nix/nix.conf, not the HM
    # user config
    nix.package = pkgs.lixPackageSets.stable.lix;
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # no .home — NixOS derives /home/<name> for isNormalUser
    users.users.${config.flake.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
    };

    programs.zsh.enable = true;
    # zim's completion module owns compinit (shell.nix) — the NixOS
    # /etc/zshrc must not run it first
    programs.zsh.enableCompletion = false;

    security.sudo.wheelNeedsPassword = false;
  };
}
