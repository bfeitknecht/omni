{ lib, ... }: {
  # declared (instead of relying on the freeform flake output)
  # so every class file can contribute one attribute
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
  };

  options.flake.username = lib.mkOption {
    type = lib.types.str;
    default = "user";
  };

  config = {
    # the single place user identity is defined — hosts, standalone
    # configs and features all read config.flake.username
    flake.username = "bf";
  };
}
