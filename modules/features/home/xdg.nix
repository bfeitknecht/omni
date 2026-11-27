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

      # nix: ~/.nix-profile and ~/.nix-defexpr move to ~/.local/state/nix
      # (HM follows the setting for its own profile path). Linux only: the
      # system nix.conf sets it too (system/linux.nix). On darwin the lix
      # installer owns /etc/nix/nix.conf and bf is not trusted, so the daemon
      # ignored it with a warning; anti keeps the two links in ~.
      nix.settings.use-xdg-base-directories = lib.mkIf pkgs.stdenv.hostPlatform.isLinux (
        lib.mkDefault true
      );
    };
}
