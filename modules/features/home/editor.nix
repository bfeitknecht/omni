{ inputs, ... }: {
  flake.modules.homeManager.editor = {
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

    programs.helix.enable = true;
  };
}
