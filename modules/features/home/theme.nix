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

      # The command line in both shells: zsh-syntax-highlighting's own
      # defaults, as ANSI indices (never hex), and nushell set to look the
      # same. A command shows red and bold (1) while it is unknown or
      # incomplete, and green (2) as soon as it exists. Keywords, strings
      # and redirections yellow (3), globs blue (4), variables in strings
      # cyan (6), paths underlined, comments and hints bright black (8),
      # the rest the terminal's foreground.
      #
      # zsh: zsh-syntax-highlighting and zsh-autosuggestions (zimfw). Set
      # after zimfw's init (order 1500 > the default 1000 in shell.nix).
      programs.zsh.initContent = lib.mkOrder 1500 ''
        typeset -gA ZSH_HIGHLIGHT_STYLES
        ZSH_HIGHLIGHT_STYLES=(
          default                       none
          unknown-token                 fg=1,bold
          reserved-word                 fg=3
          alias                         fg=2
          suffix-alias                  fg=2,underline
          global-alias                  fg=6
          builtin                       fg=2
          function                      fg=2
          command                       fg=2
          precommand                    fg=2,underline
          hashed-command                fg=2
          arg0                          fg=2
          autodirectory                 fg=2,underline
          commandseparator              none
          redirection                   fg=3
          path                          underline
          path_pathseparator            underline
          path_prefix                   underline
          globbing                      fg=4
          history-expansion             fg=4
          single-hyphen-option          none
          double-hyphen-option          none
          single-quoted-argument        fg=3
          double-quoted-argument        fg=3
          dollar-quoted-argument        fg=3
          back-quoted-argument          none
          rc-quote                      fg=6
          dollar-double-quoted-argument fg=6
          back-double-quoted-argument   fg=6
          back-dollar-quoted-argument   fg=6
          command-substitution-delimiter none
          process-substitution-delimiter none
          assign                        none
          named-fd                      none
          numeric-fd                    none
          comment                       fg=8
        )
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

        export LS_COLORS="$(${pkgs.vivid}/bin/vivid generate ansi)"
      '';

      # nushell: the shapes (command line) and the value colours (tables),
      # in named ANSI colours. dark_gray is bright black (8). Resolved
      # externals get their own shape, so an unknown command stays red.
      programs.nushell.extraConfig = lib.mkOrder 500 ''
        $env.config.highlight_resolved_externals = true
        $env.config.color_config = ($env.config.color_config | merge {
          shape_garbage: { fg: red attr: b }
          shape_external: { fg: red attr: b }
          shape_external_resolved: green
          shape_internalcall: green
          shape_custom: green
          shape_keyword: yellow
          shape_externalarg: default
          shape_string: yellow
          shape_string_interpolation: cyan
          shape_raw_string: yellow
          shape_redirection: yellow
          shape_int: default
          shape_float: default
          shape_bool: default
          shape_nothing: default
          shape_binary: default
          shape_datetime: default
          shape_filepath: { attr: u }
          shape_directory: { attr: u }
          shape_globpattern: blue
          shape_flag: default
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
