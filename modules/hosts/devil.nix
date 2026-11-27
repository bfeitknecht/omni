{
  inputs,
  config,
  lib,
  ...
}:
let
  # x86_64-linux since 2026-11-23: devil moved to rzbl (amd64 Blade). Kata
  # VMs on rbpi (arm64 Pi) wedged within minutes and left orphan qemus that
  # poisoned the node; amd64 KVM on rzbl is stable.
  system = "x86_64-linux";

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

        # The docker-container profile's registration unit hangs: lix's
        # nix-store --load-db waits in an epoll loop with no fds registered
        # in this container. It blocks the systemd job queue, so sshd
        # sessions and every later unit queue forever (the "devil freezes"
        # of 2026-11-22/23, on both nodes). The boot command already
        # registers the image store paths, so drop the unit.
        systemd.units."register-nix-paths.service".enable = lib.mkForce false;

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
        # Tailscale SSH is the only way in (no sshd since 2026-11-24): devil's
        # own tailnet node `devil`, tagged tag:devil; the tailnet policy lets
        # bf's own devices ssh in as bf (`ssh bf@devil`). Userspace
        # networking: the Kata VM has no /dev/net/tun. State on the PVC
        # (/nix is the PVC; --state/--statedir after the unit's own flags
        # win) so a pod restart keeps the node. First start: `sudo tailscale
        # up --ssh --accept-dns=false --hostname=devil --advertise-tags=tag:devil`
        # (from `kubectl exec`), open the link. Break-glass: kubectl exec.
        services.tailscale = {
          enable = true;
          interfaceName = "userspace-networking";
          extraDaemonFlags = [
            "--state=/nix/var/lib/tailscale/tailscaled.state"
            "--statedir=/nix/var/lib/tailscale"
          ];
          # cluster DNS stays the resolver; MagicDNS is not needed here
          extraSetFlags = [
            "--ssh"
            "--accept-dns=false"
          ];
        };
        systemd.tmpfiles.rules = [ "d /nix/var/lib/tailscale 0700 root root -" ];

        users.users.${config.flake.username} = {
          hashedPasswordFile = "/run/secrets-for-users/login/devil";
          # the personal Rex server keeps its sessions while bf is logged out
          linger = true;
        };

        # Prebuilt Linux binaries (the opencode npm package ships one) expect
        # the standard glibc loader; nix-ld provides it.
        programs.nix-ld.enable = true;

        # claude-code is the only unfree package: opencode's Claude Agent
        # provider runs `claude` from PATH (subscription login: `claude`, /login)
        nixpkgs.config.allowUnfreePredicate = pkg: lib.getName pkg == "claude-code";

        home-manager.users.${config.flake.username} = {
          # Rex personal server for bf (systemd user service). Clients come in
          # over Tailscale SSH only (ssh://devil): no own Rex tailnet node
          # (`deviler` is gone since 2026-11-27).
          services.rex.enable = true;

          # The agents run here as bf, each inside agent-sandbox
          # (_sandbox.nix): no sudo, no keys, no way out to bf's Rex or
          # systemd. opencode (its background service holds the sessions;
          # Zed remote, Rex and the TUI all reach the same ones; providers
          # from features/home/agents.nix) and Claude Code. From the phone:
          # Rex into devil.
          home.packages =
            let
              sandbox = pkgs.callPackage ./_sandbox.nix { };
              sandboxed =
                name: pkg: pkgs.writeShellScriptBin name ''exec ${lib.getExe sandbox} ${lib.getExe pkg} "$@"'';
            in
            [
              sandbox
              (sandboxed "claude" pkgs.claude-code)
              (sandboxed "opencode" (pkgs.callPackage ./_opencode.nix { }))
            ];
        };
        # declarative password
        users.mutableUsers = false;

        sops = {
          defaultSopsFile = ../../secrets/secrets.sops.yaml;
          age.keyFile = "/home/${config.flake.username}/.config/sops/age/keys.txt";
          secrets."login/devil".neededForUsers = true;
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
