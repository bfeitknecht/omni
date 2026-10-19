{ lib, ... }: {
  # binds the nix-ecosystem tools nixpkgs builds against lix to the
  # lixPackageSets.stable variants.
  #
  # nixos-rebuild-ng and nix-direnv must stay out: binding them makes the lix
  # scope force itself during config eval (installer-tools / HM direnv
  # defaults) — infinite recursion. nixos-rebuild-ng is re-bound to the
  # system lix by the base installer-tools module anyway.
  flake.overlays.lix =
    final: prev:
    lib.genAttrs [
      "colmena"
      "nix-du"
      "nix-eval-jobs"
      "nix-fast-build"
      "nix-init"
      "nix-serve-ng"
      "nix-update"
      "nixos-anywhere"
      "nixpkgs-review"
      "nixpkgs-reviewFull"
      "nil"
      "nurl"
    ] (name: prev.lixPackageSets.stable.${name});
}
