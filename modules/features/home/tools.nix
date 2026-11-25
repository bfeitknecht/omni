{ ... }: {
  flake.modules.homeManager.tools = { pkgs, ... }: {
    programs.ripgrep.enable = true;
    programs.fd.enable = true;
    programs.bat.enable = true;
    programs.eza.enable = true;
    programs.bottom.enable = true;
    programs.television.enable = true;
    programs.uv.enable = true;

    # TUIs for git, containers and databases
    programs.lazygit.enable = true;
    programs.lazydocker.enable = true;
    programs.lazysql.enable = true;

    # Completions for 1000+ CLIs in zsh and nushell. zsh is wired by hand in
    # shell.nix: it must load after zimfw's compinit.
    programs.carapace = {
      enable = true;
      enableZshIntegration = false;
      enableNushellIntegration = true;
    };

    # File manager. Text previews go through bat, so yazi highlights exactly
    # like cat and the pager (theme.nix: bat in ANSI colours).
    programs.yazi = {
      enable = true;
      enableZshIntegration = true;
      enableNushellIntegration = true;
      settings.plugin.prepend_previewers = [
        {
          mime = "text/*";
          run = ''piper -- bat --plain --color=always --paging=never "$1"'';
        }
      ];
    };

    programs.tealdeer = {
      enable = true;
      settings = {
        display = {
          compact = false;
          use_pager = true;
        };
        updates = {
          auto_update = true;
        };
      };
    };

    home.packages = with pkgs; [
      dust
      yq
      # GNU-compatible coreutils in Rust, under the plain names (ls, cp, ...)
      uutils-coreutils-noprefix
      age
      sops
      lua
      proton-pass-cli
      tailscale
    ];
  };
}
