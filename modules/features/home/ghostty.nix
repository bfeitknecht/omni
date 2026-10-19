{
  flake.homeModules.ghostty =
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
