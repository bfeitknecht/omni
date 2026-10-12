{ inputs, ... }: {
  flake.homeModules.secrets = { config, lib, ... }: {
    imports = [ inputs.sops-nix.homeManagerModules.sops ];

    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    sops.defaultSopsFile = lib.mkIf
      (builtins.pathExists ../../secrets/secrets.sops.yaml)
      ../../secrets/secrets.sops.yaml;
  };
}
