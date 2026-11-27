{ inputs, config, ... }:
let
  system = "aarch64-darwin";
in
{
  flake.darwinConfigurations.anti = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      { nixpkgs.hostPlatform = system; }
      { imports = [ config.flake.modules.darwin.default ]; }
      inputs.nix-homebrew.darwinModules.nix-homebrew
      {
        # all three macOS names (HostName sets LocalHostName too);
        # install.sh sets them before the first switch
        networking.hostName = "anti";
        networking.computerName = "anti";

        # Tailscale: the open-source tailscaled (launchd daemon), not the
        # app: only this variant runs a Tailscale SSH server on macOS, so
        # `ssh anti` and Rex `ssh://anti` work from devil and the phone. No
        # menu bar icon; the CLI is `tailscale`. First start, once:
        # `sudo tailscale up --ssh --accept-routes --advertise-tags=tag:anti`.
        services.tailscale.enable = true;
        # nix-darwin links /etc/resolver/ts.net into /etc/static; tailscaled
        # writes /etc/resolver itself and refuses the symlink ("openat
        # ts.net: path escapes from parent"), so the DNS setup fails
        environment.etc."resolver/ts.net".enable = inputs.nixpkgs.lib.mkForce false;

        # nix-darwin installs and owns Homebrew itself;
        # the homebrew block below manages only what the Brewfile lists
        nix-homebrew = {
          enable = true;
          user = config.flake.username;
        };

        homebrew = {
          enable = true;
          onActivation.cleanup = "zap";
          casks = [
            ## development
            "zed"
            "ghostty"
            "orbstack"
            "utm"
            ## security
            "proton-mail"
            "proton-pass"
            "protonvpn"
            # creating
            "obsidian"
            "prusaslicer"
            "audacity"
            ## communication
            "spotify"
            "whatsapp"
            "signal"
            "discord"
            ## rice
            # "mikker/tap/dinky" # tiling wm, no SIP change; cask in the tap mikker/tap (homebrew.taps)
            # "tuna"
            # "kindavim"
            # sketchybar: no tap, no cask: services.sketchybar (nix-darwin); also
            # services.jankyborders and services.aerospace
            # "ukulele"
            # "hammerspoon"
            # "stats" # ?
          ];
        };
      }
    ];
  };
}
