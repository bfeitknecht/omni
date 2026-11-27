{ ... }: {
  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "master";
        # HTTPS to Forgejo with the token tea stores (`tea login add`);
        # GitHub: gh adds its own helper (programs.gh.gitCredentialHelper)
        credential."https://git.0xbf.ch".helper = "!${pkgs.lib.getExe pkgs.tea} login helper";
        user = {
          name = "Basil Feitknecht";
          email = "bfeitknecht@ethz.ch";
        };
      };
      ignores = [
        ".direnv/"
        ".private/"
        ".DS_Store"
      ];
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        navigate = true;
        line-numbers = true;
      };
    };

    programs.gh = {
      enable = true;
      extensions = with pkgs; [
        gh-dash
        gh-enhance
      ];
    };
    home.packages = with pkgs; [
      tea
      glab
    ];
  };
}
