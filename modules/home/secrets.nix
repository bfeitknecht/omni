{ inputs, ... }: {
  flake.homeModules.secrets = { config, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # once `sops secrets/secrets.sops.yaml` exists, wire entries here, e.g.:
    # sops.defaultSopsFile = ../../secrets/secrets.sops.yaml;
    # sops.secrets."ssh/id_ed25519".path = "${config.home.homeDirectory}/.ssh/id_ed25519";
  };
}
