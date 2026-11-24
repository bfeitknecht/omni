{ ... }: {
  flake.modules.homeManager.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "master";
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
