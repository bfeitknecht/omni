{ config, ... }: {
  flake.homeModules.default = { ... }: {
    imports = with config.flake.homeModules; [
      shell
      tools
      git
      editor
      nix
      secrets
    ];

    home.stateVersion = "26.11";
  };
}
