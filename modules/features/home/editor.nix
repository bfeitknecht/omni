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

      # Zed: the app comes from the homebrew cask on darwin; HM writes only
      # the user settings (merged into Zed's own file, so the settings UI
      # still works). Vanilla apart from theme (features/home/theme.nix) and
      # font. Language servers, formatters and tasks go per project in
      # .zed/settings.json, not here.
      programs.zed-editor = {
        enable = true;
        package = null;
        userSettings = {
          buffer_font_family = "CommitMono Nerd Font";
          ui_font_family = ".SystemUIFont";
          terminal.font_family = "CommitMono Nerd Font";
          telemetry = {
            diagnostics = false;
            metrics = false;
          };
        };
      };
    };
}
