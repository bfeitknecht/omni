{ inputs, ... }: {
  # Rex (Superlogical): persistent terminal sessions, plus `oc` (opencode). devil runs the server
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

      # `oc` on the Macs: the opencode TUI attached to the cluster server,
      # through devil (only devil may reach it; the session runs in the
      # isolated opencode VM, so closing the laptop stops nothing). devil has
      # its own `oc` (hosts/devil.nix).
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
        (pkgs.writeShellScriptBin "oc" ''
          exec ssh -t devil oc "$@"
        '')
      ];

      programs.rex = {
        # the flake's package on every host, macOS too (the release zip has
        # only the `rex` binary; the Rex app has no Homebrew cask)
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
