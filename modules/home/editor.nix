{ ... }: {
  flake.homeModules.editor = {
    programs.neovim.enable = true;
    programs.helix.enable = true;

    home.sessionVariables.EDITOR = "nvim";
  };
}
