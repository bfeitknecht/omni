{ lib, ... }: {
  options.flake.username = lib.mkOption {
    type = lib.types.str;
    default = "bf";
  };
}
