{ inputs, ... }: {
  # Rex (Superlogical): persistent terminal sessions. devil runs the server
  # (hosts/devil.nix turns on services.rex); every other host is a client
  # and reaches devil over ssh, with the devil.internal entry in ssh.nix.
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
        enable = true;
        # macOS: the Rex app ships the server and the cli
        package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;
        # the server reads init.lua; devil does not list itself
        config = lib.mkIf (!config.services.rex.enable) (
          pkgs.writeText "init.lua" ''
            rex.host{ label = "devil", endpoint = "ssh://devil.internal" }
          ''
        );
      };
    };
}
