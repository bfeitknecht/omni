{ inputs, ... }: {
  # Rex (Superlogical): persistent terminal sessions. devil runs the server
  # (hosts/devil.nix turns on services.rex); every other host is a client
  # and reaches devil over Tailscale SSH (the `devil` entry in ssh.nix).
  flake.modules.homeManager.rex =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.rex.homeManagerModules.default ];

      programs.rex = {
        # the flake's package on every host, macOS too: the `rex` CLI (the
        # darwin release zip has only the binary; the Rex app has no Nix
        # package and no Homebrew cask yet)
        enable = true;
        # the server reads init.lua; devil does not list itself
        config = lib.mkIf (!config.services.rex.enable) (
          pkgs.writeText "init.lua" ''
            rex.host{ label = "devil", endpoint = "ssh://devil" }
          ''
        );
      };
    };
}
