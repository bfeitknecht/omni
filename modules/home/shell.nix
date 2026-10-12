{ ... }: {
  flake.homeModules.shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # starship interpolates ${count}-style variables in format strings;
      # built by concatenation so nix ${ interpolation stays out of the way
      cnt = "$" + "{count}";
      aheadCnt = "$" + "{ahead_count}";
      behindCnt = "$" + "{behind_count}";

      # shared between the two per-shell variants — zsh renders a single
      # line closed by starship's character module, nushell renders two
      # lines with the vim-aware indicator owning line 2
      shared = {
        add_newline = false;
        right_format = "($shlvl )($status )$git_branch$git_state$git_status$time";

        username = {
          format = "$user";
          show_always = true;
        };
        hostname = {
          format = "$hostname";
          ssh_only = false;
        };
        directory = {
          format = "$path";
          truncation_length = 0;
          truncate_to_repo = false;
        };
        shlvl = {
          disabled = false;
          format = "$symbol";
          symbol = "#";
          repeat = true;
          threshold = 1;
        };
        status = {
          format = ''\[$status\]($style)'';
          style = "bold red";
        };
        git_branch.format = ''\($branch'';
        git_state.format = "$state( $progress_current/$progress_total) ";
        git_status = {
          # the closing paren lives here so the GIT cell always renders in a
          # work tree (up_to_date =)
          format = ''$all_status$ahead_behind\) '';
          up_to_date = "=";
          ahead = ">" + cnt;
          behind = "<" + behindCnt;
          diverged = "><" + aheadCnt + "/" + behindCnt;
          untracked = "%" + cnt;
          stashed = "$" + cnt;
          conflicted = "!" + cnt;
          modified = "*" + cnt;
          staged = "+" + cnt;
        };
        time = {
          disabled = false;
          format = "$time";
          time_format = "%Y-%m-%dT%H:%M:%S%z";
        };
      };

      zshSettings = shared // {
        format = "$username@$hostname:$directory $character";
        character = {
          success_symbol = "%";
          error_symbol = "X";
        };
      };

      # no $line_break: the newline is re-appended to PROMPT_COMMAND nu-side
      # (external capture strips it); the indicator owns line 2
      nuSettings = shared // {
        format = "$username@$hostname:$directory";
      };
    in
    {
      home.packages = [
        # nixpkgs ships zimfw.zsh without a bin wrapper
        (pkgs.writeShellScriptBin "zimfw" ''
          exec ${pkgs.zimfw}/zimfw.zsh "$@"
        '')
      ];

      programs.starship = {
        enable = true;
        # per-shell configs: HM writes zsh.toml at configPath and exports
        # STARSHIP_CONFIG via session variables; nushell re-points it at
        # nushell.toml in env.nu (see extraEnv below)
        configPath = "${config.xdg.configHome}/starship/zsh.toml";
        settings = zshSettings;
        enableZshIntegration = true;
        # declarative `starship init nu` (built via runCommand) `use`d in
        # extraConfig — reads STARSHIP_CONFIG at prompt render time
        enableNushellIntegration = true;
      };

      xdg.configFile."starship/nushell.toml".source =
        (pkgs.formats.toml { }).generate "starship-nushell"
          nuSettings;

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

          # any-nix-shell's prompt hook is not sourced — its precmd
          # unconditionally re-sets RPROMPT, clobbering starship's
          # right_format. The command wrappers stay: nix-shell / nix run /
          # nix develop drop into zsh instead of bash
          nix-shell() { ${pkgs.any-nix-shell}/bin/.any-nix-shell-wrapper zsh "$@"; }
          nix() {
            if [[ "$1" == "run" || "$1" == "develop" ]]; then
              ${pkgs.any-nix-shell}/bin/.any-nix-wrapper zsh "$@"
            else
              command nix "$@"
            fi
          }

        ''
        + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''

          [[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
        '';
      };

      # bat everywhere: as cat, as the man pager, as the general pager
      home.sessionVariables = {
        MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        PAGER = "bat";
      };

      programs.bat = {
        enable = true;
        config = {
          paging = "never";
        };
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
          show_banner = false;
        };
        shellAliases.cat = "bat --paging=never";
        extraEnv = ''
          # the session-variable STARSHIP_CONFIG points at the zsh variant;
          # nushell selects its own (two-line) variant
          $env.STARSHIP_CONFIG = ($nu.default-config-dir | path dirname | path join "starship" "nushell.toml")
        '';
        extraConfig = ''
          # starship's nu init forces the right prompt onto the last line;
          # here the right cell stays on line 1 (the indicator owns line 2)
          $env.config.render_right_prompt_on_last_line = false

          # the prompt definitions call starship explicitly; the newline +
          # symbol are nu-side (the indicators) — starship's own output
          # loses a trailing line_break on capture
          $env.PROMPT_COMMAND = { || ^${pkgs.starship}/bin/starship prompt }
          $env.PROMPT_COMMAND_RIGHT = { ||
              ^${pkgs.starship}/bin/starship prompt --right $"--status=($env.LAST_EXIT_CODE)"
          }

          # the indicators own line 2
          $env.PROMPT_INDICATOR = "\n: "
          $env.PROMPT_INDICATOR_VIM_INSERT = "\n: "
          $env.PROMPT_INDICATOR_VIM_NORMAL = "\n$ "

          # submitted lines collapse to just the mode indicator — no path,
          # no right cell
          $env.TRANSIENT_PROMPT_COMMAND = { || "" }
          $env.TRANSIENT_PROMPT_COMMAND_RIGHT = { || "" }
          $env.TRANSIENT_PROMPT_INDICATOR = ": "
          $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = ": "
          $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = "$ "

          use user *
        '';
      };

      # seed the user module once; HM never owns it afterwards, so runtime
      # edits in ~/.config/nushell/user/ survive switches
      home.activation.omniNushellUserModule =
        let
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

      # F to correct the previous command
      programs.pay-respects = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
      };

      programs.zoxide = {
        enable = true;
        # zoxide takes over cd entirely
        options = [ "--cmd cd" ];
      };
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        enableNushellIntegration = true;
      };
    };
}
