{ inputs, ... }: {
  flake.modules.homeManager.editor = {
    imports = [ inputs.nvf.homeManagerModules.default ];

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

    programs.helix.enable = true;
  };
}
