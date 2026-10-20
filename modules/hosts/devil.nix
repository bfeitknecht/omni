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
        imports = [
          "${inputs.nixpkgs}/nixos/modules/profiles/docker-container.nix"
          inputs.sops-nix.nixosModules.sops
        ];

        # flake-only image: no bundled nixpkgs channel
        system.installer.channel.enable = false;

        networking.hostName = "devil";
        time.timeZone = "Europe/Zurich";
        system.stateVersion = "26.11";

        documentation = {
          enable = true;
          man.enable = true;
        };

        # lix is the system nix (the nixpkgs default is upstream nix)
        nix.package = pkgs.lixPackageSets.stable.lix;
        # root/sudo nix (nh os switch) reads /etc/nix/nix.conf, not the HM user config
        nix.settings.experimental-features = [
          "nix-command"
          "flakes"
        ];

        users.users.${config.flake.username} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          shell = pkgs.zsh;
          # teleport sessions create no login session (no pam_systemd) —
          # user manager (and sops-nix's user service) must start at boot
          linger = true;
          hashedPasswordFile = "/run/secrets-for-users/login/devil";
        };
        # declarative password
        users.mutableUsers = false;

        sops = {
          defaultSopsFile = ../../secrets/secrets.sops.yaml;
          age.keyFile = "/home/${config.flake.username}/.config/sops/age/keys.txt";
          secrets."login/devil".neededForUsers = true;
          secrets."ssh/devil.pub" = { }; # placeholder
        };

        programs.zsh.enable = true;
        # zim's completion module owns compinit (shell.nix) —
        # the NixOS /etc/zshrc must not run it first
        programs.zsh.enableCompletion = false;

        security.sudo.wheelNeedsPassword = false;

        # kubelet bind-mounts /etc/hostname and /etc/hosts into container —
        # NixOS's etc activation cannot replace bind mounts and warns on every switch
        environment.etc."hostname".enable = false;
        environment.etc."hosts".enable = false;

        networking.useDHCP = false;
        networking.resolvconf.enable = false;
        networking.firewall.allowedTCPPorts = [
          2222 # sshd — the devil.internal TCPRoute (gateway listener devilssh)
          3022 # teleport agent (stays until the teardown after the friend demo)
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
            # authorized_keys come from sops
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

        systemd.services.teleport = {
          description = "Teleport agent (ssh_service)";
          wantedBy = [ "multi-user.target" ];
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
  # rootfs tarball for `docker import`. docker-container profile ships /init,
  # registers store db at boot and keeps /init fresh across in-container switches
  flake.packages.aarch64-linux.devil = nixos.config.system.build.tarball;
}
