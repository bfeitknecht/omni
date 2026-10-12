{ config, ... }: {
  flake.homeModules.default = { ... }: {
    imports = with config.flake.homeModules; [
      shell
      tools
      git
      editor
      nix
      ssh
      secrets
    ];

    home.stateVersion = "26.11";

    # machines with pre-existing dotfiles: back up on first switch instead
    # of failing the activation
    home.backupFileExtension = "backup";
  };
}
