{ ... }: {
  flake.modules.homeManager.gpg = { config, ... }: {
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
      user.signingkey = "84A27B4385BD9467D0FA55E70C88C11F14E660C6";
      commit.gpgsign = true;
      tag.gpgsign = true;
    };
  };
}
