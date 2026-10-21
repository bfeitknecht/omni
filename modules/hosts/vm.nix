{ inputs, config, ... }:
let
  # the host's platform, declared once — see devil.nix
  system = "aarch64-linux";

  # let-bound so the runner package below can reference the configuration
  # without reading config.flake.nixosConfigurations (freeform-merge recursion)
  nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      # wrapped in its own module — see devil.nix
      { imports = [ config.flake.modules.nixos.default ]; }
      inputs.microvm.nixosModules.microvm
      {
        networking.hostName = "vm";

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
          shares = [
            {
              tag = "ro-store";
              source = "/nix/store";
              mountPoint = "/nix/.ro-store";
            }
          ];
          writableStoreOverlay = "/nix/.rw-store";

          # user-mode networking (slirp); falls back to TCG without /dev/kvm
          interfaces = [
            {
              type = "user";
              id = "qemu";
              mac = "02:00:00:4f:6d:6e";
            }
          ];
        };
      }
    ];
  };
in
{
  flake.nixosConfigurations.vm = nixos;
  flake.packages.${system}.vm = nixos.config.microvm.declaredRunner;
}
