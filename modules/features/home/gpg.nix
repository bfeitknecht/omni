{ ... }: {
  flake.modules.homeManager.gpg =
    { config, lib, ... }:
    let
      fingerprint = "84A27B4385BD9467D0FA55E70C88C11F14E660C6";
      secret = config.sops.secrets."gpg/private".path;
      gpg = "${config.programs.gpg.package}/bin/gpg";
    in
    {
      programs.gpg.enable = true;

      sops.secrets."gpg/private" = {
        mode = "0400";
      };

      # Not programs.gpg.publicKeys: HM's importGpgKeys runs right after
      # linkGeneration, before sops-nix has written the secret (on darwin
      # the launchd agent writes it later), and then the activation fails.
      # The keyring is persistent: import once, skip when the key is there.
      home.activation.importGpgSecretKey =
        lib.hm.dag.entryAfter [ "sopsSecretsWait" "createGpgHomedir" ]
          ''
            export GNUPGHOME=${lib.escapeShellArg config.programs.gpg.homedir}
            if ${gpg} --list-secret-keys ${fingerprint} >/dev/null 2>&1; then
              verboseEcho "gpg: secret key ${fingerprint} already imported"
            elif waitForSecret ${secret}; then
              run ${gpg} --batch --quiet --import ${secret}
            else
              warnEcho "gpg: ${secret} is missing, secret key not imported. Switch again when sops-nix has run."
            fi
            unset GNUPGHOME
          '';

      programs.git.settings = {
        user.signingkey = fingerprint;
        commit.gpgsign = true;
        tag.gpgsign = true;
      };
    };
}
