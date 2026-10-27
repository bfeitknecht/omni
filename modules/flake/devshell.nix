{ ... }: {
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShellNoCC {
      packages = with pkgs; [
        # nil links libnixexpr — take the lix-built one
        lixPackageSets.stable.nil
        nixfmt
        nixfmt-tree
        nix-output-monitor
      ];
    };

    formatter = pkgs.nixfmt-tree;
  };
}
