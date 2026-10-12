{ ... }: {
  flake.homeModules.tools = { pkgs, ... }: {
    programs.ripgrep.enable = true;
    programs.fd.enable = true;
    programs.bat.enable = true;
    programs.eza.enable = true;
    programs.bottom.enable = true;
    programs.television.enable = true;
    programs.uv.enable = true;

    home.packages = with pkgs; [
      dust
      tlrc
      age
      sops
      lua
      deno
    ];
  };
}
