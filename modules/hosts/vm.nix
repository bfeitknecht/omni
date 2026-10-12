{ inputs, config, ... }:
let
  # let-bound so the runner package below can reference the configuration
  # without reading config.flake.nixosConfigurations (freeform-merge recursion)
  nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = "aarch64-linux"; }
      { nixpkgs.overlays = [ config.flake.overlays.lix ]; }
      inputs.home-manager.nixosModules.home-manager
      inputs.microvm.nixosModules.microvm
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${config.flake.username}.imports = [
          config.flake.homeModules.default
        ];
      }
      ({ pkgs, ... }: {
        networking.hostName = "vm";
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
        };

        programs.zsh.enable = true;

        # disposable test bed: no password mechanism until the secrets
        # iteration wires one
        security.sudo.wheelNeedsPassword = false;

        # console-only; the qemu serial console is the primary path
        services.getty.autologinUser = config.flake.username;

        microvm = {
          hypervisor = "qemu";
          # non-null cpu skips the runner's unconditional -enable-kvm (which
          # would hard-require KVM); "max" works under both KVM and TCG
          cpu = "max";
          vcpu = 2;
          # never 2048: qemu hangs with exactly 2GB (microvm.nix issue #171)
          mem = 3072;
          socket = "/var/tmp/omni-vm.qmp";

          # host store read-only + writable tmpfs overlay: the guest can
          # build and `nh os switch` against the shared store
          shares = [ {
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          } ];
          writableStoreOverlay = "/nix/.rw-store";

          # user-mode networking (slirp); falls back to TCG without /dev/kvm
          interfaces = [ {
            type = "user";
            id = "qemu";
            mac = "02:00:00:4f:6d:6e";
          } ];
        };
      })
    ];
  };
in {
  flake.nixosConfigurations.vm = nixos;
  flake.packages.aarch64-linux.vm = nixos.config.microvm.declaredRunner;
}
