{ inputs, config, ... }:
let
  system = "aarch64-linux";

  # let-bound so the tarball package below can reference the configuration
  # without reading config.flake.nixosConfigurations (freeform-merge recursion)
  nixos = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      { imports = [ config.flake.modules.nixos.default ]; }
      ({ pkgs, ... }: {
        imports = [
          "${inputs.nixpkgs}/nixos/modules/profiles/docker-container.nix"
          inputs.sops-nix.nixosModules.sops
        ];

        # flake-only image: no bundled nixpkgs channel
        system.installer.channel.enable = false;

        networking.hostName = "devil";

        documentation = {
          enable = true;
          man.enable = true;
        };

        # kubelet bind-mounts /etc/hostname and /etc/hosts into container —
        # NixOS's etc activation cannot replace bind mounts and warns on every switch
        environment.etc."hostname".enable = false;
        environment.etc."hosts".enable = false;

        networking.useDHCP = false;
        networking.resolvconf.enable = false;
        # cluster DNS: kresd + knotd resolver Service (infra/kubernetes/applications/dns/)
        networking.nameservers = [ "10.96.0.53" ];

        # inside kata VM build sandbox cannot resolve DNS
        nix.settings.sandbox = false;
        networking.firewall.allowedTCPPorts = [
          2222 # sshd — the devil.internal TCPRoute (gateway listener devilssh)
          7681 # ttyd — the devil.internal HTTPRoute (ghostty-web)
        ];

        services.openssh = {
          enable = true;
          ports = [ 2222 ];
          settings = {
            # keys only — the login password exists for the ghostty-web pty
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
            # authorized_keys come from sops, rendered at boot
            AuthorizedKeysFile = "/run/secrets/ssh/devil.pub";
          };
          hostKeys = [
            {
              path = "/var/lib/ssh/ssh_host_ed25519_key";
              type = "ed25519";
            }
          ];
        };

        # ttyd serves the ghostty-web page (infra ConfigMap mounted at /srv/ghostty-web)
        # and puts real `login` prompt on the pty —
        # PAM validates bf's password, shell is full home config.
        # internal-allowlist middleware is network gate, login prompt is auth.
        systemd.services.ghostty-web = {
          description = "ghostty-web terminal (devil.internal, ttyd + login)";
          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.ttyd}/bin/ttyd -W -O -p 7681 -I /srv/ghostty-web/index.html ${pkgs.util-linux}/bin/login";
            Restart = "on-failure";
            RestartSec = "5s";
          };
        };

        users.users.${config.flake.username} = {
          hashedPasswordFile = "/run/secrets-for-users/login/devil";
        };
        # declarative password
        users.mutableUsers = false;

        sops = {
          defaultSopsFile = ../../secrets/secrets.sops.yaml;
          age.keyFile = "/home/${config.flake.username}/.config/sops/age/keys.txt";
          secrets."login/devil".neededForUsers = true;
          # sshd reads the pub half as the login user — 0444 beats any
          # render owner (verified in-VM: root-owned 0444 → accepted)
          secrets."ssh/devil.pub".mode = "0444";
        };
      })
    ];
  };
in
{
  flake.nixosConfigurations.devil = nixos;
  # rootfs tarball for `docker import`. docker-container profile ships /init,
  # registers store db at boot and keeps /init fresh across in-container switches
  flake.packages.${system}.devil = nixos.config.system.build.tarball;
}
