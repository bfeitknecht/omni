{ lib, ... }: {
  # declared (instead of relying on the freeform flake output) so every
  # class file can contribute one attribute
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  config = {
    flake.username = "bf";
    systems = [ "aarch64-linux" "aarch64-darwin" ];
  };
}
