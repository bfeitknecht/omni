{ inputs, config, ... }:
let
  # let-bound so the tarball package below can reference the configuration
  # without reading config.flake.nixosConfigurations (freeform-merge recursion)
  nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = "aarch64-linux"; }
      { nixpkgs.overlays = [ config.flake.overlays.lix ]; }
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${config.flake.username}.imports = [
          config.flake.homeModules.default
        ];
      }
      ({ pkgs, ... }: {
        imports = [ "${inputs.nixpkgs}/nixos/modules/profiles/docker-container.nix" ];

        # flake-only image: no bundled nixpkgs channel
        system.installer.channel.enable = false;

        networking.hostName = "devil";
        time.timeZone = "Europe/Zurich";
        system.stateVersion = "26.11";

        # lix is the system nix (the nixpkgs default is upstream nix)
        nix.package = pkgs.lixPackageSets.stable.lix;
        # system-level: root/sudo nix (nh os switch) reads /etc/nix/nix.conf,
        # not the HM user config
        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        users.users.${config.flake.username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          shell = pkgs.zsh;
          # ssh keys land in ~/.ssh/authorized_keys via the sops HM class
          # (modules/home/secrets.nix) in a future iteration
        };

        programs.zsh.enable = true;

        # no password mechanism until the secrets iteration wires one
        security.sudo.wheelNeedsPassword = false;

        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
        };
      })
    ];
  };
in {
  flake.nixosConfigurations.devil = nixos;
  # rootfs tarball for `docker import`; the docker-container profile ships
  # /init, registers the store db at boot and keeps /init fresh across
  # in-container switches
  flake.packages.aarch64-linux.devil = nixos.config.system.build.tarball;
}
