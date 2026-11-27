{ inputs, ... }: {
  flake.modules.homeManager.editor =
    { lib, pkgs, ... }:
    {
      # nvf renamed homeManagerModules to homeModules (2026-11 lock bump warning)
      imports = [ inputs.nvf.homeModules.default ];

      programs.nvf = {
        enable = true;
        # sets EDITOR=nvim
        defaultEditor = true;

        settings.vim = {
          viAlias = false;
          vimAlias = true;
          lineNumberMode = "relNumber";
          searchCase = "smart";
          undoFile.enable = true;
          lsp.enable = true;
        };
      };

      # darwin (anti): Zed for VISUAL (git commit, crontab -e, ...); EDITOR
      # stays nvim for terminal-only use. The cask's CLI, full path: nushell
      # does not load Homebrew's PATH.
      home.sessionVariables = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        VISUAL = "/opt/homebrew/bin/zed --wait";
      };

      # darwin: Zed is the default app for plain text. GUI apps do not read
      # VISUAL: Ghostty's Settings (Cmd-,) runs `open -t` on its config,
      # and that opens the plain-text handler (TextEdit before this).
      home.activation.zedPlainText = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          run ${lib.getExe pkgs.duti} -s dev.zed.Zed public.plain-text all \
            || warnEcho "duti: Zed is not the plain-text handler (is Zed installed?)"
        ''
      );

      # Zed: the app comes from the homebrew cask on darwin; HM writes only
      # the user settings (merged into Zed's own file, so the settings UI
      # still works; agent servers and SSH hosts stay in that file). Zed's
      # default theme. Language servers and tasks go per project in
      # .zed/settings.json; the one global rule for them:
      # format on save, through the language server.
      programs.zed-editor = {
        enable = true;
        package = null;
        # always there: Nix syntax and the nil language server (nil itself
        # comes from each project's dev shell, through direnv)
        extensions = [ "nix" ];
        # Cmd-K in the terminal: Zed clears its buffer behind the shell's back,
        # so nushell (reedline) still has its old prompt row and jumps back
        # there on Enter. Send ctrl-l instead: the shell clears (nushell:
        # ClearScrollback, shell.nix) and redraws its prompt itself.
        userKeymaps = [
          {
            context = "Terminal";
            bindings."cmd-k" = [
              "terminal::SendKeystroke"
              "ctrl-l"
            ];
          }
        ];
        userSettings = {
          # editor (from the old settings, .private/settings.json)
          vim_mode = true;
          vim.toggle_relative_line_numbers = true;
          which_key.enabled = false;
          format_on_save = "on";
          formatter = "language_server";
          autosave = "on_focus_change";
          restore_on_startup = "last_session";
          on_last_window_closed = "quit_app";
          when_closing_with_no_tabs = "keep_window_open";
          cli_default_open_behavior = "existing_window";
          use_system_path_prompts = true;
          auto_signature_help = true;
          use_smartcase_search = true;
          soft_wrap = "editor_width";
          preferred_line_length = 100;
          show_wrap_guides = false;
          expand_excerpt_lines = 7;
          diff_view_style = "split";
          diagnostics.inline = {
            enabled = true;
            padding = 4;
          };
          scrollbar = {
            show = "auto";
            axes.horizontal = false;
          };
          toolbar.selections_menu = false;
          file_finder.include_ignored = "indexed";
          private_files = [ "**/*.secret" ];
          # the cask updates Zed (brew), not Zed itself
          auto_update = false;

          # fonts (anti's current settings)
          buffer_font_family = "CommitMono Nerd Font";
          buffer_font_size = 15;
          buffer_font_features.calt = false;
          ui_font_family = ".SystemUIFont";
          ui_font_size = 16;

          # layout: tabs without icons, with git status; no tab bar buttons;
          # git panel left; no search or collaboration button
          tabs = {
            file_icons = false;
            git_status = true;
          };
          tab_bar = {
            show_tab_bar_buttons = false;
            show_nav_history_buttons = false;
          };
          git_panel.dock = "left";
          search.button = false;
          collaboration_panel.button = false;

          terminal = {
            font_family = "CommitMono Nerd Font";
            # the editor has no copy on select; the terminal does
            copy_on_select = true;
            show_count_badge = false;
            toolbar.breadcrumbs = false;
            scrollbar.show = "never";
          };
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
        };
      };
    };
}
