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
    # flakes only: no channels (no ~/.nix-defexpr), and the per-user nix
    # links under ~/.local/state/nix, not in ~ (features/home/xdg.nix)
    nix.channel.enable = false;
    nix.settings.use-xdg-base-directories = true;

    # no .home — NixOS derives /home/<name> for isNormalUser
    users.users.${config.flake.username} = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
    };

    # ssh from Ghostty sends TERM=xterm-ghostty; without its terminfo, zle
    # has no terminal definition (broken echo, broken line editing)
    environment.systemPackages = [ pkgs.ghostty.terminfo ];

    programs.zsh.enable = true;
    # zim's completion module owns compinit (shell.nix) — the NixOS
    # /etc/zshrc must not run it first
    programs.zsh.enableCompletion = false;

    security.sudo.wheelNeedsPassword = false;
  };
}
