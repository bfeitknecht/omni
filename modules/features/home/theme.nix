{ ... }: {
  # How every tool gets its colours. One rule: shells and CLI tools use the 16
  # ANSI colours only, never hex. The frontend (Ghostty, Rex, Zed's terminal)
  # maps the 16 to its theme, light or dark, so everything follows the
  # system appearance from one place.
  #
  # The theme is Ghostty's "Builtin Light" and "Builtin Dark". Ghostty and
  # Rex render the ANSI colours themselves. Zed is the one frontend that needs
  # the palette as hex: `palettes` below, copied from Ghostty's theme files
  # (Ghostty.app/Contents/Resources/ghostty/themes/Builtin {Light,Dark}).
  flake.modules.homeManager.theme =
    { lib, pkgs, ... }:
    let
      palettes = {
        "Builtin Dark" = {
          appearance = "dark";
          background = "#000000";
          foreground = "#bbbbbb";
          selection = "#b5d5ff";
          ansi = [
            "#000000"
            "#bb0000"
            "#00bb00"
            "#bbbb00"
            "#0d0dc8"
            "#bb00bb"
            "#00bbbb"
            "#bbbbbb"
            "#555555"
            "#ff5555"
            "#55ff55"
            "#ffff55"
            "#5555ff"
            "#ff55ff"
            "#55ffff"
            "#ffffff"
          ];
        };
        "Builtin Light" = {
          appearance = "light";
          background = "#ffffff";
          foreground = "#000000";
          selection = "#b5d5ff";
          ansi = [
            "#000000"
            "#bb0000"
            "#00bb00"
            "#bbbb00"
            "#0000bb"
            "#bb00bb"
            "#00bbbb"
            "#bbbbbb"
            "#555555"
            "#ff5555"
            "#2fd92f"
            "#bfbf15"
            "#5555ff"
            "#ff55ff"
            "#22cccc"
            "#ffffff"
          ];
        };
      };

      names = [
        "black"
        "red"
        "green"
        "yellow"
        "blue"
        "magenta"
        "cyan"
        "white"
      ];

      # A Zed theme from a Ghostty palette. Plain on purpose: one background,
      # greys from the palette, syntax in the same ANSI roles bat uses.
      zedTheme =
        name: p:
        let
          c = builtins.elemAt p.ansi;
          dark = p.appearance == "dark";
          muted = c 8;
          surface = if dark then "#111111" else "#f2f2f2";
          border = if dark then "#333333" else "#dddddd";
          style = color: { inherit color; };
        in
        {
          inherit name;
          inherit (p) appearance;
          style = {
            background = p.background;
            "surface.background" = surface;
            "elevated_surface.background" = surface;
            "panel.background" = p.background;
            "editor.background" = p.background;
            "editor.foreground" = p.foreground;
            "editor.gutter.background" = p.background;
            "editor.line_number" = muted;
            "editor.active_line_number" = p.foreground;
            "editor.active_line.background" = surface;
            "title_bar.background" = p.background;
            "status_bar.background" = p.background;
            "toolbar.background" = p.background;
            "tab_bar.background" = surface;
            "tab.active_background" = p.background;
            "tab.inactive_background" = surface;
            text = p.foreground;
            "text.muted" = muted;
            border = border;
            "border.variant" = border;
            "element.selected" = "${p.selection}55";
            "ghost_element.hover" = "${muted}33";
            "ghost_element.selected" = "${p.selection}55";
            "terminal.background" = p.background;
            "terminal.foreground" = p.foreground;
            players = [
              {
                cursor = p.foreground;
                background = p.foreground;
                selection = "${p.selection}66";
              }
            ];
            syntax = {
              comment = style muted;
              string = style (c 2);
              keyword = style (c 5);
              function = style (c 4);
              type = style (c 3);
              number = style (c 6);
              constant = style (c 6);
              boolean = style (c 6);
              attribute = style (c 3);
              tag = style (c 4);
              property = style p.foreground;
              variable = style p.foreground;
              punctuation = style p.foreground;
              operator = style p.foreground;
            };
          }
          // lib.listToAttrs (
            lib.imap0 (i: n: {
              name = "terminal.ansi.${if i < 8 then n else "bright_${n}"}";
              value = c i;
            }) (names ++ names)
          );
        };
    in
    {
      # Zed: the two Ghostty themes, following the system appearance.
      programs.zed-editor.themes.ghostty = {
        "$schema" = "https://zed.dev/schema/themes/v0.2.0.json";
        name = "Ghostty";
        author = "omni";
        themes = lib.mapAttrsToList zedTheme palettes;
      };
      programs.zed-editor.userSettings.theme = {
        mode = "system";
        light = "Builtin Light";
        dark = "Builtin Dark";
      };

      # Syntax highlighting in ANSI: bat (cat, man, previews in yazi and
      # television) and delta (git diffs).
      programs.bat.config.theme = "ansi";
      programs.delta.options.syntax-theme = "ansi";

      # LS_COLORS for ls, eza, fd, yazi: vivid's ANSI theme. Called by store
      # path (HM's vivid module calls a bare `vivid`, which breaks nushell
      # when the profile is not on PATH yet); generating it at build time
      # would need a builder of each host's platform during evaluation.
      programs.zsh.initContent = ''
        export LS_COLORS="$(${pkgs.vivid}/bin/vivid generate ansi)"
      '';
      programs.nushell.extraEnv = ''
        $env.LS_COLORS = (^${pkgs.vivid}/bin/vivid generate ansi)
      '';
    };
}
