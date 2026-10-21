{ config, ... }: {
  flake.modules.homeManager.default = { ... }: {
    imports = with config.flake.modules.homeManager; [
      shell
      tools
      git
      editor
      ghostty
      nix
      ssh
      gpg
      secrets
    ];

    home.stateVersion = "26.11";

    # XDG everywhere — including darwin, where nushell et al. would
    # otherwise fall back to ~/Library/Application Support
    xdg.enable = true;

    # machines with pre-existing dotfiles: back up on first switch instead
    # of failing the activation
    home.backupFileExtension = "backup";
  };
}
