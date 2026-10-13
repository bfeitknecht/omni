{ ... }: {
  flake.homeModules.shell =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = [
        # nixpkgs ships zimfw.zsh without a bin wrapper
        (pkgs.writeShellScriptBin "zimfw" ''
          exec ${pkgs.zimfw}/zimfw.zsh "$@"
        '')
      ];

      programs.starship =
        let
          # starship interpolates ${count}-style variables in format strings;
          # built by concatenation so nix ${ interpolation stays out of the way
          count = "$" + "{count}";
          ahead = "$" + "{ahead_count}";
          behind = "$" + "{behind_count}";
        in
        {
          enable = true;
          configPath = "${config.xdg.configHome}/starship/starship.toml";
          settings = {
            add_newline = false;
            format = "($custom.prompt )$character";
            right_format = "($shlvl )($status )($custom.git )($custom.time)";

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
            character = {
              success_symbol = "%";
              error_symbol = "X";
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
            git_branch.format = "$branch";
            git_state.format = "$state( $progress_current/$progress_total) ";
            git_status = {
              format = "$all_status$ahead_behind ";
              up_to_date = "=";
              ahead = ">" + count;
              behind = "<" + behind;
              diverged = "><" + ahead + "/" + behind;
              untracked = "%" + count;
              stashed = "$" + count;
              conflicted = "!" + count;
              modified = "*" + count;
              staged = "+" + count;
            };
            time = {
              disabled = false;
              format = "$time";
              time_format = "%Y-%m-%dT%H:%M:%S%z";
            };
            custom.git = {
              format = "\($git_branch$git_state$git_status\)";
              description = "The current Git information";
              require_repo = true;
            };
            custom.prompt = {
              format = "$username@$hostname:$directory";
              description = "The left prompt (conditional)";
              when = ''[[ -n "$TMUX" ||  -n "$ZED_TERM" ]]'';
              shell = [
                "${pkgs.zsh}/bin/zsh"
                "-f"
                "-c"
              ];
            };
            custom.time = {
              format = "$time";
              description = "The current time (conditional)";
              when = ''[[ -n "$TMUX" ||  -n "$ZED_TERM" ]]'';
              shell = [
                "${pkgs.zsh}/bin/zsh"
                "-f"
                "-c"
              ];
            };
          };
          enableZshIntegration = true;
          enableNushellIntegration = true;
        };

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
          table_mode = "markdown";
        };
        shellAliases.cat = "bat --paging=never";
        extraEnv = ''
          $env.STARSHIP_CONFIG = ($nu.default-config-dir | path dirname | path join "starship" "starship.toml")
        '';
        extraConfig = ''
          $env.STARSHIP_SHELL = "nu"
          $env.config.render_right_prompt_on_last_line = false

          $env.PROMPT_COMMAND = { ||
            ^${pkgs.starship}/bin/starship module custom.prompt
          }
          # $env.PROMPT_COMMAND_RIGHT = { ||
          #   ^${pkgs.starship}/bin/starship prompt --right $"--status=($env.LAST_EXIT_CODE)"
          # }

          $env.PROMPT_INDICATOR = ""
          $env.PROMPT_INDICATOR_VI_NORMAL = "\n$ "
          $env.PROMPT_INDICATOR_VI_INSERT = "\n: "
          $env.PROMPT_MULTILINE_INDICATOR = "\n... "

          $env.TRANSIENT_PROMPT_COMMAND = { || "" }
          $env.TRANSIENT_PROMPT_COMMAND_RIGHT = { || "" }
          $env.TRANSIENT_PROMPT_INDICATOR = "$ "
          $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = "$ "
          $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = "$ "
          $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = "    "

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

      # f to correct the previous command
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
