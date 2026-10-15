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
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        users.users.${config.flake.username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          shell = pkgs.zsh;
        };

        programs.zsh.enable = true;

        # no password mechanism until the secrets iteration wires one
        security.sudo.wheelNeedsPassword = false;

        # No sshd — devil is reachable only through the teleport proxy (tailnet + `tsh ssh`).
        # The agent's ssh_service IS the SSH endpoint:
        # it dials OUT to the proxy tunnel, nothing dials in, and the pod
        # carries no Service and no HTTPRoute.
        environment.etc."teleport/teleport.yaml".text = ''
          version: v3
          teleport:
            nodename: devil
            # in-cluster address of the teleport proxy Service; the proxy's
            # TLS cert covers this name (infra teleport certificate.yaml).
            # Agents pin the host CA during the token join, so the
            # internal-CA-signed cert validates.
            auth_server: teleport.teleport.svc.cluster.local:443
            # fingerprint of the auth host CA (tctl tokens add prints it);
            # without it the token join cannot verify the proxy's
            # internal-CA-signed cert. Public material — safe to embed.
            ca_pin: sha256:943b04599846c81bfc6f6019894bcd6c5c1c2737ba49c3052f5850b055c10b22
          auth_service:
            enabled: "no"
          proxy_service:
            enabled: "no"
          ssh_service:
            enabled: "yes"
            listen_addr: 0.0.0.0:3022
            labels:
              role: dev-box
        '';

        # join token arrives as a mounted k8s Secret (devil-teleport-token);
        # --token accepts a file path. The pod mounts it at
        # /etc/teleport-secrets, not /run/secrets — systemd inside the kata
        # VM may classify itself as a VM and overmount /run with a tmpfs,
        # hiding the secret mount.
        systemd.services.teleport = {
          description = "Teleport agent (ssh_service)";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.teleport}/bin/teleport start --config=/etc/teleport/teleport.yaml --token=/etc/teleport-secrets/teleport-token";
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };
      })
    ];
  };
in
{
  flake.nixosConfigurations.devil = nixos;
  # rootfs tarball for `docker import`; the docker-container profile ships
  # /init, registers the store db at boot and keeps /init fresh across
  # in-container switches
  flake.packages.aarch64-linux.devil = nixos.config.system.build.tarball;
}
