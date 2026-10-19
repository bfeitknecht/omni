{ ... }: {
  flake.homeModules.git = { pkgs, ... }: {
    programs.git = {
      enable = true;
      settings = {
        init.defaultBranch = "master";
        user = {
          name = "bfeitknecht";
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

    programs.gh.enable = true;
    programs.jujutsu.enable = true;

    home.packages = with pkgs; [ tea ];
  };
}
