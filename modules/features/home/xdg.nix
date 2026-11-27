{ ... }: {
  # Tools that put a directory in ~ by default, moved to the XDG base
  # directories. Only what each tool supports itself (an env var or a
  # setting); no wrappers. What stays in ~ and why: README.md (XDG).
  flake.modules.homeManager.xdg =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (config.xdg) configHome cacheHome stateHome;
    in
    {
      home.sessionVariables = {
        # kubectl: the discovery and http cache (~/.kube/cache) and the
        # default kubeconfig (~/.kube/config). infra passes its own
        # --kubeconfig, so this one is only the fallback.
        KUBECONFIG = "${configHome}/kube/config";
        KUBECACHEDIR = "${cacheHome}/kube";
        # npm: the package cache (~/.npm) and the user npmrc (~/.npmrc)
        NPM_CONFIG_CACHE = "${cacheHome}/npm";
        NPM_CONFIG_USERCONFIG = "${configHome}/npm/npmrc";
        # Mistral Vibe: config, sessions and logs (~/.vibe)
        VIBE_HOME = "${configHome}/vibe";
      };

      # atuin: the logs (~/.atuin/logs); config and data already follow XDG
      programs.atuin.settings.logs.dir = "${stateHome}/atuin/logs";

      # nix: the per-user links (~/.nix-profile, ~/.nix-defexpr) go to
      # ~/.local/state/nix. The system nix.conf sets it (system/linux.nix);
      # a home nix.conf must not: bf is not a trusted user, so the daemon
      # warned on every nix command. Only a standalone home (`nh home
      # switch`) sets it, because HM takes its profile path from it there;
      # inside a host the profile is /etc/profiles/per-user anyway.
      nix.settings.use-xdg-base-directories = lib.mkIf (
        pkgs.stdenv.hostPlatform.isLinux && !config.submoduleSupport.enable
      ) (lib.mkDefault true);
    };
}
