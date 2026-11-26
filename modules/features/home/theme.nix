{ ... }: {
  # How every tool gets its colours. One rule: shells and CLI tools use the 16
  # ANSI colours only, never hex. The frontend (Ghostty, Rex, Zed's terminal)
  # maps the 16 to its theme, light or dark, so everything follows the
  # system appearance from one place.
  #
  # Ghostty and Rex use their built-in themes; Zed uses its default theme.
  flake.modules.homeManager.theme =
    { lib, pkgs, ... }:
    {
      # Syntax highlighting in ANSI: bat (cat, man, previews in yazi and
      # television) and delta (git diffs).
      programs.bat.config.theme = "ansi";
      programs.delta.options.syntax-theme = "ansi";

      # LS_COLORS for ls, eza, fd, yazi: vivid's ANSI theme. Called by store
      # path (HM's vivid module calls a bare `vivid`, which breaks nushell
      # when the profile is not on PATH yet); generating it at build time
      # would need a builder of each host's platform during evaluation.
      # zsh: in the command-line block below.
      programs.nushell.extraEnv = ''
        $env.LS_COLORS = (^${pkgs.vivid}/bin/vivid generate ansi)
      '';

      # The command line in both shells, same roles as bat and Zed: keywords
      # magenta (5), commands blue (4), strings green (2), numbers and options
      # cyan (6), comments and hints bright black (8), errors red (1), the
      # rest the terminal's foreground. Numbers are ANSI indices, never hex.
      #
      # zsh: zsh-syntax-highlighting and zsh-autosuggestions (zimfw). Set
      # after zimfw's init (order 1500 > the default 1000 in shell.nix).
      programs.zsh.initContent = lib.mkOrder 1500 ''
        typeset -gA ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES=(
          default                       none
          unknown-token                 fg=1,bold
          reserved-word                 fg=5
          alias                         fg=4
          suffix-alias                  fg=4
          global-alias                  fg=4
          builtin                       fg=4
          function                      fg=4
          command                       fg=4
          precommand                    fg=4,underline
          hashed-command                fg=4
          arg0                          fg=4
          autodirectory                 fg=4,underline
          commandseparator              none
          redirection                   none
          path                          underline
          path_pathseparator            underline
          path_prefix                   underline
          globbing                      fg=6
          history-expansion             fg=6
          single-hyphen-option          fg=6
          double-hyphen-option          fg=6
          single-quoted-argument        fg=2
          double-quoted-argument        fg=2
          dollar-quoted-argument        fg=2
          back-quoted-argument          fg=5
          rc-quote                      fg=6
          dollar-double-quoted-argument fg=6
          back-double-quoted-argument   fg=6
          back-dollar-quoted-argument   fg=6
          command-substitution-delimiter fg=5
          process-substitution-delimiter fg=5
          assign                        none
          named-fd                      none
          numeric-fd                    none
          comment                       fg=8
        )
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

        export LS_COLORS="$(${pkgs.vivid}/bin/vivid generate ansi)"
      '';

      # nushell: the shapes (command line) and the value colours (tables),
      # in named ANSI colours. dark_gray is bright black (8).
      programs.nushell.extraConfig = lib.mkOrder 500 ''
        $env.config.color_config = ($env.config.color_config | merge {
          shape_keyword: magenta
          shape_internalcall: blue
          shape_external: blue
          shape_externalarg: default
          shape_custom: blue
          shape_garbage: { fg: default bg: red attr: b }
          shape_string: green
          shape_string_interpolation: cyan
          shape_raw_string: green
          shape_int: cyan
          shape_float: cyan
          shape_bool: cyan
          shape_nothing: cyan
          shape_binary: cyan
          shape_datetime: cyan
          shape_filepath: { attr: u }
          shape_directory: { attr: u }
          shape_globpattern: cyan
          shape_flag: cyan
          shape_operator: default
          shape_pipe: default
          shape_variable: default
          shape_vardecl: default
          shape_signature: default
          hints: dark_gray
          string: default
          int: cyan
          float: cyan
          bool: cyan
          nothing: dark_gray
          date: magenta
          duration: cyan
          filesize: cyan
          range: cyan
          binary: cyan
          header: { fg: default attr: b }
          row_index: dark_gray
          separator: dark_gray
          empty: dark_gray
        })
      '';
    };
}
