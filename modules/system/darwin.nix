{ inputs, config, ... }: {
  # the shared darwin class — the hm plumbing + shell gotchas the darwin
  # host (auto) shares with the nixos class (system/linux.nix)
  flake.modules.darwin.default = { ... }: {
    imports = [ inputs.home-manager.darwinModules.home-manager ];

    nixpkgs.overlays = [ config.flake.overlays.lix ];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      users.${config.flake.username}.imports = [
        config.flake.modules.homeManager.default
      ];
    };

    # the lix installer owns the daemon and /etc/nix/nix.conf
    nix.enable = false;

    # the darwin home fact, once — HM derives home.homeDirectory from it
    users.users.${config.flake.username}.home = "/Users/${config.flake.username}";
    system.primaryUser = config.flake.username;
    system.stateVersion = 7;

    # zimfw's completion module owns compinit — the global one would
    # populate _comps first (zim warning); promptInit stays out of the
    # way (starship owns the prompt)
    programs.zsh = {
      enableCompletion = false;
      promptInit = "";
    };
  };
}
