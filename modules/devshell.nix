{ ... }: {
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShellNoCC {
      packages = with pkgs; [
        # nil links libnixexpr — take the lix-built one
        lixPackageSets.stable.nil
        nixfmt-rfc-style
      ];
    };

    formatter = pkgs.nixfmt;
  };
}
