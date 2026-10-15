{ ... }: {
  flake.homeModules.gpg = { config, ... }: {
    programs.gpg.enable = true;

    sops.secrets."gpg/private" = {
      mode = "0400";
    };

    # HM imports keyring keys at activation (importGpgKeys),
    # after the sops-nix activation entry has materialized the secret;
    # gpg --import takes secret keys, so keyring setup is fully automatic.
    programs.gpg.publicKeys = [
      { source = config.sops.secrets."gpg/private".path; }
    ];

    programs.git.settings = {
      user.signingkey = "F804FDB7ACA417B06989F4303621C839358AA0E1";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };
}
