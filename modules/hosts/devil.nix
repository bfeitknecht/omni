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
        ];

        services.openssh = {
          enable = true;
          ports = [ 2222 ];
          settings = {
            # keys only — the login password is for sudo and the console
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

        users.users.${config.flake.username} = {
          hashedPasswordFile = "/run/secrets-for-users/login/devil";
          # the personal Rex server keeps its sessions while bf is logged out
          linger = true;
        };

        # Prebuilt Linux binaries (the opencode npm package ships one) expect
        # the standard glibc loader; nix-ld provides it.
        programs.nix-ld.enable = true;

        home-manager.users.${config.flake.username} = {
          # Rex personal server for bf (systemd user service). Clients come in
          # over ssh (ssh://devil.internal) or over the tailnet: Rex runs its
          # own Tailscale node `devil` (https://devil.<tailnet>.ts.net), owned
          # by bf's account, so only bf's devices get in. First start: open
          # the sign-in link from `rex server status`. The identity stays in
          # ~/.local/state/rex on the PVC. ("rex" on the tailnet is the Mac app.)
          services.rex = {
            enable = true;
            tailscale = {
              enable = true;
              hostname = "devil";
            };
          };

          # opencode client for the isolated server in the cluster (infra
          # applications/opencode, Kata VM). The version must match the
          # server pin in infra opencode.yaml: bump both together. v2 clients
          # connect with --server (v1 `attach` is gone); the session runs in
          # the server VM, devil is only the screen. The v2 server always
          # requires a password: OPENCODE_PASSWORD comes from sops, the same
          # value as infra opencode-secrets key server-password.
          home.packages =
            let
              version = "2.3.2";
            in
            [
              (pkgs.writeShellScriptBin "opencode" ''
                export PATH=${pkgs.nodejs_22}/bin:$PATH
                exec npx -y @opencode/cli@${version} "$@"
              '')
              (pkgs.writeShellScriptBin "oc" ''
                export OPENCODE_PASSWORD="$(cat /run/secrets/opencode/server-password)"
                export PATH=${pkgs.nodejs_22}/bin:$PATH
                exec npx -y @opencode/cli@${version} --server http://opencode.opencode.svc "$@"
              '')
            ];
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
          # opencode server password (same value as infra opencode-secrets
          # server-password); the `oc` wrapper reads it at runtime
          secrets."opencode/server-password" = {
            mode = "0400";
            owner = config.flake.username;
          };
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
