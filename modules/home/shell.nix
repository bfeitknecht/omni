{ ... }: {
  flake.homeModules.shell = { config, lib, pkgs, ... }: {
    home.packages = [
      # nixpkgs ships zimfw.zsh without a bin wrapper
      (pkgs.writeShellScriptBin "zimfw" ''
        exec ${pkgs.zimfw}/zimfw.zsh "$@"
      '')
    ];

    programs.zsh = {
      enable = true;
      dotDir = "${config.xdg.configHome}/zsh";
      # zimfw's completion module owns compinit
      enableCompletion = false;
      history = {
        size = 100000;
        save = 100000;
        share = true;
        path = "${config.xdg.stateHome}/zsh/.zsh_history";
      };

      initContent = ''
        ZIM_CONFIG_FILE="${config.xdg.configHome}/zsh/zimrc"
        ZIM_HOME="${config.xdg.cacheHome}/zsh/zim"
        # installs missing modules and (re)builds init.zsh when outdated
        if [[ ! -e "''${ZIM_HOME}/init.zsh" ]] || [[ "''${ZIM_CONFIG_FILE}" -nt "''${ZIM_HOME}/init.zsh" ]]; then
          source ${pkgs.zimfw}/zimfw.zsh init 2>/dev/null || true
        fi
        [[ -e "''${ZIM_HOME}/init.zsh" ]] && source "''${ZIM_HOME}/init.zsh"

        any-nix-shell zsh | source /dev/stdin

        command_not_found_handler() {
          local db="''${XDG_CACHE_HOME:-''$HOME/.cache}/nix-index/files"
          if [[ ! -s "''$db" ]]; then
            print -u2 "comma: no nix-index database yet — build it once with: nix-index"
            return 127
          fi
          comma "$@"
        }
      '' + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''

        [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
      '';
    };

    xdg.configFile."zsh/zimrc".text = ''
      zmodule environment
      zmodule input
      zmodule completion
      zmodule zsh-users/zsh-autosuggestions
      zmodule zsh-users/zsh-syntax-highlighting
    '';

    programs.nushell = {
      enable = true;
      settings = {
        edit_mode = "vi";
      };
      extraConfig = ''
        $env.PROMPT_INDICATOR = ": "
        $env.PROMPT_INDICATOR_VIM_INSERT = ": "
        $env.PROMPT_INDICATOR_VIM_NORMAL = "$ "

        $env.TRANSIENT_PROMPT_COMMAND = { || "$" }

        use user *
      '';
    };

    # seed the user module once; HM never owns it afterwards, so runtime
    # edits in ~/.config/nushell/user/ survive switches
    home.activation.omniNushellUserModule = let
      userMod = pkgs.writeText "omni-nushell-user-mod" ''
        # omni user module — imported by config.nu (`use user *`).
        # Created once by home-manager; never overwritten.
        #
        #   env vars / config : export-env { $env.FOO = "bar" }
        #   functions         : export def greet [] { "hi" }
        #   aliases           : export alias ll = eza -la --icons
        #   constants         : export const editor = "nvim"
        #   split into files  : create user/foo.nu, then here: export use ./foo.nu
      '';
    in
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.xdg.configHome}/nushell/user"
        [ -e "${config.xdg.configHome}/nushell/user/mod.nu" ] || \
          install -m 644 ${userMod} "${config.xdg.configHome}/nushell/user/mod.nu"
      '';

    programs.zoxide.enable = true;
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
