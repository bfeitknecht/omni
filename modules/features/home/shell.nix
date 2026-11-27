{ ... }: {
  flake.modules.homeManager.shell =
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
            format = "(\${custom.prompt} )$character";
            right_format =
              ''($shlvl)( $status)( \($git_branch( $git_state)($git_status)\))'' + "( \${custom.time})";

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
              # off by default in starship: without this [ERR] never shows
              disabled = false;
              # the one colour in the prompt: bold red on error (ANSI red)
              format = ''\[$status\]($style)'';
              style = "bold red";
            };
            git_branch.format = "$branch";
            git_state = {
              format = "$state( $progress_current/$progress_total)";
              rebase = "REBASE";
              merge = "MERGE";
              revert = "REVERT";
              cherry_pick = "CHERRY";
              bisect = "BISECT";
              am = "AM";
              am_or_rebase = "AM/REBASE";
            };
            git_status = {
              format = "( $all_status)( $ahead_behind)";
              up_to_date = "=";
              # ahead and behind know only ${count}; ${ahead_count} and
              # ${behind_count} exist in diverged alone (behind showed a bare <)
              ahead = ">" + count;
              behind = "<" + count;
              diverged = ">" + ahead + "<" + behind;
              untracked = "%" + count;
              # a literal $ must be escaped (\$) in a starship format string;
              # "$${count}" failed to parse and hid the stash count
              stashed = "\\$" + count;
              conflicted = "!" + count;
              modified = "*" + count;
              staged = "+" + count;
              # starship defaults are the symbols ✘ and »: ASCII like the rest
              deleted = "-" + count;
              renamed = "~" + count;
            };
            custom.prompt = {
              description = "The left prompt (conditional)";
              format = "$output";
              when = ''[[ -z "$ZED_TERM" && -z "$REX_SESSION" ]]'';
              # user at host in directory
              command = ''printf '%s@%s:%s' "$USER" "$HOST" '' + "\"\${PWD/#$HOME/~}\""; # holy abomination
              shell = [
                "${pkgs.zsh}/bin/zsh"
                "-f"
              ];
            };
            custom.time = {
              format = "$output";
              description = "The current time (conditional)";
              when = ''[[ -z "$ZED_TERM" && -z "$REX_SESSION" ]]'';
              # date with ISO format string
              command = "date +'%Y-%m-%dT%H:%M:%S%z'";
              shell = [
                "${pkgs.zsh}/bin/zsh"
                "-f"
              ];
            };
          };
          enableZshIntegration = true;
          enableNushellIntegration = false;
        };

      programs.zsh = {
        enable = true;
        dotDir = "${config.xdg.configHome}/zsh";
        defaultKeymap = "emacs";
        # zimfw's completion module owns compinit
        enableCompletion = false;
        history = {
          size = 100000;
          save = 100000;
          share = true;
          path = "${config.xdg.stateHome}/zsh/.zsh_history";
        };

        initContent = ''
          # no space after the right prompt (zsh keeps one column free by default)
          ZLE_RPROMPT_INDENT=0

          ZIM_CONFIG_FILE="${config.xdg.configHome}/zsh/zimrc"
          ZIM_HOME="${config.xdg.cacheHome}/zsh/zim"
          # installs missing modules and (re)builds init.zsh when outdated
          if [[ ! -e "''${ZIM_HOME}/init.zsh" ]] || [[ "''${ZIM_CONFIG_FILE}" -nt "''${ZIM_HOME}/init.zsh" ]]; then
            source ${pkgs.zimfw}/zimfw.zsh init 2>/dev/null || true
          fi
          [[ -e "''${ZIM_HOME}/init.zsh" ]] && source "''${ZIM_HOME}/init.zsh"

          # carapace completions need compinit, which zimfw ran just above
          source <(${pkgs.carapace}/bin/carapace _carapace zsh)

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

      # bat everywhere: as cat, as the man pager, as the general pager.
      # MANROFFOPT=-c: groff emits overstrike instead of SGR — col strips
      # overstrikes cleanly but eats the "\x1b[" of SGR sequences, which
      # used to leak literal fragments (1m, 0m, 4m) into the pager input.
      # PAGER is bat --plain: piped text (tldr, git without delta, ...) gets
      # no header, no grid, no "STDIN" title. bat pages through less -RF,
      # and -F quits at once when the text fits the screen.
      home.sessionVariables = {
        MANROFFOPT = "-c";
        MANPAGER = "sh -c 'col -bx | bat -l man -p'";
        PAGER = "bat --plain";
      };

      programs.bat = {
        enable = true;
        config = {
          paging = "auto";
          pager = "less -RF";
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
          table.mode = "markdown";
        };
        shellAliases.cat = "bat --paging=auto";
        extraEnv = ''
          $env.STARSHIP_CONFIG = ($nu.default-config-dir | path dirname | path join "starship" "starship.toml")
        '';
        extraConfig = lib.mkMerge [
          ''
            $env.STARSHIP_SHELL = "nu"
            $env.config.render_right_prompt_on_last_line = false

            # The prompt is monochrome in both shells, red on error aside:
            # starship sets no other style,
            # and nushell's own prompt colours (reedline paints the prompt
            # green, the indicators cyan) are cancelled by a reset at the start
            # of every prompt string. Colour on the command line is theme.nix.
            let reset = (ansi reset)

            $env.PROMPT_COMMAND = { ||
              # compact in Zed and Rex (REX_SESSION is set in every Rex block)
              if ('ZED_TERM' in $env or 'REX_SESSION' in $env) {
                $reset
              } else {
                $reset ++ (^${pkgs.starship}/bin/starship module custom.prompt) ++ "\n"
              }
            }
            $env.PROMPT_COMMAND_RIGHT = { ||
              $reset ++ (^${pkgs.starship}/bin/starship prompt --right $"--status=($env.LAST_EXIT_CODE)")
            }

            $env.PROMPT_INDICATOR = $reset
            $env.PROMPT_INDICATOR_VI_NORMAL = $"($reset)$ "
            $env.PROMPT_INDICATOR_VI_INSERT = $"($reset): "
            $env.PROMPT_MULTILINE_INDICATOR = $"($reset)... "

            $env.TRANSIENT_PROMPT_COMMAND = { || $reset }
            $env.TRANSIENT_PROMPT_COMMAND_RIGHT = { || $reset }
            $env.TRANSIENT_PROMPT_INDICATOR = $"($reset)$"
            $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = $"($reset)    "

            use user *
          ''
          # HM's direnv hook, with direnv's messages captured and printed instead
          (lib.mkAfter ''
            $env.config = ($env.config? | default {})
            $env.config.hooks = ($env.config.hooks? | default {})
            $env.config.hooks.pre_prompt = (
                $env.config.hooks.pre_prompt?
                | default []
                | append {||
                    let result = (^${lib.getExe config.programs.direnv.package} export json | complete)
                    if ($result.stderr | is-not-empty) {
                        print --stderr --no-newline $result.stderr
                    }
                    let direnv = ($result.stdout | from json --strict | default {})

                    for key in ($direnv | columns) {
                        if ($direnv | get $key) == null {
                            hide-env --ignore-errors $key
                        }
                    }

                    $direnv
                    | items {|key, value|
                        let value = do (
                            {
                              "PATH": {
                                from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
                                to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
                              }
                            }
                            | merge ($env.ENV_CONVERSIONS? | default {})
                            | get ([[value, optional, insensitive]; [$key, true, true] [from_string, true, false]] | into cell-path)
                            | if ($in | is-empty) { {|x| $x} } else { $in }
                        ) $value
                        return [ $key $value ]
                    }
                    | where {|pair| $pair.1 != null }
                    | into record
                    | load-env
                }
            )
          '')
        ];
      };

      # config.nu does `use user *`: an empty mod.nu when there is none. HM
      # never owns it, so runtime edits in ~/.config/nushell/user/ survive
      # switches. Early in the activation: a later failing step must not
      # leave nushell without it.
      home.activation.omniNushellUserModule =
        lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
          ''
            run mkdir -p "${config.xdg.configHome}/nushell/user"
            [ -e "${config.xdg.configHome}/nushell/user/mod.nu" ] || \
              run touch "${config.xdg.configHome}/nushell/user/mod.nu"
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
        # HM's nushell hook redirects to /dev/stderr; when stderr is a pipe
        # (Zed's remote terminal) nushell cannot open it. Own hook in programs.nushell.
        enableNushellIntegration = false;
      };

      programs.atuin = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          # enter pulls the selection into the buffer, it does not run it
          enter_accept = false;
          sync_address = "https://atuin.0xbf.ch";
          ai.enabled = false;
        };
        enableNushellIntegration = true;
        # keep the up arrow as plain history navigation — ctrl-r is the picker
        flags = [ "--disable-up-arrow" ];
        # atuin rewrites config.toml itself; let HM own the file
        forceOverwriteSettings = true;
      };

      # atuin sync login from sops: atuin/key is the key file
      # (~/.local/share/atuin/key, base64), atuin/password the account
      # password. atuin reads the key from the sops path. The session token
      # lives in atuin's own store, so the login runs at activation; when
      # already logged in, atuin returns at once and reads nothing.
      sops.secrets."atuin/key" = { };
      sops.secrets."atuin/password" = { };
      programs.atuin.settings.key_path = config.sops.secrets."atuin/key".path;

      home.activation.atuinLogin =
        let
          atuin = lib.getExe config.programs.atuin.package;
          key = config.sops.secrets."atuin/key".path;
          password = config.sops.secrets."atuin/password".path;
        in
        lib.hm.dag.entryAfter [ "sopsSecretsWait" "linkGeneration" ] ''
          if waitForSecret ${key} && waitForSecret ${password}; then
            if [[ -v DRY_RUN ]]; then
              echo "${atuin} login --username bf --password - --key \"\" < ${password}"
            elif ! atuinOut=$(${atuin} login --username bf --password - --key "" < ${password} 2>&1); then
              warnEcho "atuin: login failed (no network?). Switch again, or: atuin login"
              warnEcho "$atuinOut"
            fi
            unset atuinOut
          else
            warnEcho "atuin: the sops secrets are missing, not logged in. Switch again when sops-nix has run."
          fi
        '';
    };
}
