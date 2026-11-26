{ inputs, ... }: {
  flake.modules.homeManager.secrets =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

      sops.defaultSopsFile = ../../../secrets/secrets.sops.yaml;

      # sops-nix's own activation entry has no order. It must run after the
      # new launchd agent or systemd unit is in place: else, on a first
      # switch, `launchctl bootstrap` fails (no plist yet), and later the
      # old agent or unit writes the old set of secrets. This adds the
      # order only; the script stays sops-nix's (the empty data loses).
      home.activation.sops-nix = {
        data = lib.mkOverride 1500 "";
        after = [
          "setupLaunchAgents"
          "reloadSystemd"
        ];
        before = [ ];
      };

      # sops-nix decrypts in a launchd agent on darwin: its activation entry
      # only starts the agent, the files come some seconds later. On linux the
      # entry restarts a systemd user service and waits; at boot (no user
      # systemd yet) the files come later. Entries that read a secret go
      # after this one and call `waitForSecret <path>`: it waits on darwin
      # only, and fails when the file is still missing.
      home.activation.sopsSecretsWait = lib.hm.dag.entryAfter [ "sops-nix" ] ''
        waitForSecret() {
          local tries=${if pkgs.stdenv.hostPlatform.isDarwin then "60" else "0"}
          [ -s ${lib.escapeShellArg config.sops.age.keyFile} ] || tries=0
          while [ ! -e "$1" ] && [ "$tries" -gt 0 ]; do
            sleep 1
            tries=$((tries - 1))
          done
          [ -e "$1" ]
        }
      '';
    };
}
