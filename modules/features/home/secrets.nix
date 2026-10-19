{ inputs, ... }: {
  flake.homeModules.secrets = { config, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    sops.defaultSopsFile = ../../secrets/secrets.sops.yaml;
  };
}
