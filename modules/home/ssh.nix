{ config, lib, pkgs, ... }: {
  flake.homeModules.ssh = { config, lib, pkgs, ... }: {
    # one ed25519 key per service; the private halves live in
    # secrets/secrets.sops.yaml, the public halves ride along for pasting
    # into services. sops-nix owns these paths after activation. Declared
    # only once that file exists (and is tracked), so machines without
    # secrets yet keep switching.
    sops.secrets = lib.mkIf
      (builtins.pathExists ../../secrets/secrets.sops.yaml)
      {
        "ssh/github".path = "${config.home.homeDirectory}/.ssh/github";
        "ssh/github.pub".path = "${config.home.homeDirectory}/.ssh/github.pub";
        "ssh/forgejo".path = "${config.home.homeDirectory}/.ssh/forgejo";
        "ssh/forgejo.pub".path = "${config.home.homeDirectory}/.ssh/forgejo.pub";
        "ssh/tangled".path = "${config.home.homeDirectory}/.ssh/tangled";
        "ssh/tangled.pub".path = "${config.home.homeDirectory}/.ssh/tangled.pub";
      };

    programs.ssh = {
      enable = true;

      includes = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        "~/.orbstack/ssh/config"
      ];

      # global defaults; with per-service keys, IdentitiesOnly is the policy.
      # capitalized names: they must override HM's defaults for these exact
      # keys (ssh_config is first-match-wins, duplicates would lose)
      settings."*" = {
        ForwardAgent = true;
        AddKeysToAgent = true;
        IdentitiesOnly = true;
        ServerAliveInterval = 300;
        ServerAliveCountMax = 12;
      };

      settings."github.com" = {
        user = "git";
        identityFile = "~/.ssh/github";
      };

      settings."git.0xbf.ch" = {
        user = "git";
        identityFile = "~/.ssh/forgejo";
      };

      settings."tangled.org" = {
        user = "git";
        identityFile = "~/.ssh/tangled";
      };
    };
  };
}
