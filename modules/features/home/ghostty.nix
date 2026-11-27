{
  flake.modules.homeManager.ghostty =
    { lib, pkgs, ... }:
    lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      programs.ghostty = {
        enable = true;
        # the app comes from the homebrew cask; HM manages only the config
        package = null;

        settings = {
          # follow the system appearance
          theme = "light:Builtin Light,dark:Builtin Dark";
          font-family = "CommitMono Nerd Font";
          # gamma-correct blending: anti-aliased text without the thin, light
          # edges of the native blending (dark text on light most of all)
          alpha-blending = "linear-corrected";

          # A bare window: no title bar, no traffic-light buttons, no size
          # overlay. Even padding all round.
          macos-titlebar-style = "hidden";
          resize-overlay = "never";
          window-padding-x = 10;
          window-padding-y = 8;
          window-padding-balance = true;

          # The focused split is clear: the others fade to half.
          unfocused-split-opacity = 0.5;

          # A steady block cursor, also at the prompt (no-cursor: the shell
          # integration does not change it to a bar)
          cursor-style = "block";
          cursor-style-blink = false;
          mouse-hide-while-typing = true;

          # a selection goes to the system clipboard at once
          copy-on-select = "clipboard";

          # ssh: install xterm-ghostty's terminfo on the remote host when it
          # has none, else fall back to TERM=xterm-256color
          shell-integration-features = "no-cursor,ssh-terminfo,ssh-env";
        };
      };

      # HM's darwin fonts module rsyncs /share/fonts from home.packages into
      # ~/Library/Fonts (coretext ignores nix profiles — and symlinked
      # fonts). Filtered copy: base family only, the Mono/Propo variants
      # stay out of the font picker.
      home.packages = [
        (pkgs.runCommand "commit-mono-nerd-font" { } ''
          mkdir -p $out/share/fonts/opentype/NerdFonts/CommitMono
          cp ${pkgs.nerd-fonts.commit-mono}/share/fonts/opentype/NerdFonts/CommitMono/CommitMonoNerdFont-*.otf \
            $out/share/fonts/opentype/NerdFonts/CommitMono/
        '')
      ];
    };
}
