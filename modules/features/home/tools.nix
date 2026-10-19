{ ... }: {
  flake.homeModules.tools = { pkgs, ... }: {
    programs.ripgrep.enable = true;
    programs.fd.enable = true;
    programs.bat.enable = true;
    programs.eza.enable = true;
    programs.bottom.enable = true;
    programs.television.enable = true;
    programs.uv.enable = true;

    programs.tealdeer = {
      enable = true;
      settings = {
        display = {
          compact = false;
          use_pager = true;
        };
        updates = {
          auto_update = true;
        };
      };
    };

    home.packages = with pkgs; [
      dust
      age
      sops
      lua
    ];
  };
}
