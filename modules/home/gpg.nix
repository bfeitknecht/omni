{ ... }: {
  flake.homeModules.gpg =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.gpg.enable = true;

      sops.secrets."gpg/private" = {
        mode = "0400";
      };

      programs.gpg.privateKeys = [
        {
          text = builtins.readFile config.sops.secrets."gpg/private-key".path;
        }
      ];

      programs.git.settings = {
        user.signingkey = "F804FDB7ACA417B06989F4303621C839358AA0E1";
        commit.gpgsign = true;
        tag.gpgsign = true;
      };
    };
}
