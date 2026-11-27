{ inputs, ... }: {
  # Rex (Superlogical): persistent terminal sessions. devil runs the server
  # (hosts/devil.nix turns on services.rex); every other host is a client
  # and reaches devil over Tailscale SSH (the `devil` entry in ssh.nix);
  # devil reaches anti the same way.
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
        # the hosts in the Rex app and CLI, over Tailscale SSH (ssh.nix);
        # devil runs the server and lists anti, every other host lists devil
        config = pkgs.writeText "init.lua" (
          if config.services.rex.enable then
            ''
              rex.host{ label = "anti", endpoint = "ssh://anti" }
            ''
          else
            ''
              rex.host{ label = "devil", endpoint = "ssh://devil" }
            ''
        );
      };
    };
}
