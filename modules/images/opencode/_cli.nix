# OpenCode v2 (npm @opencode/cli; opencode-ai stays on 1.x), one build for
# the isolated server image (images/opencode.nix) and devil's client
# (hosts/devil.nix): the client and server versions cannot drift apart.
# The prebuilt Bun binary needs only glibc. It is not patched: patchelf would
# break the bundle Bun appends to the file. The image links the FHS loader;
# on devil, nix-ld provides it. (The leading _ keeps import-tree out.)
{ stdenvNoCC, fetchurl }:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "2.4.0";
  src = fetchurl {
    url = "https://registry.npmjs.org/@opencode/cli-linux-x64/-/cli-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-Fj95De/tWRHlL+jWabamtzf7zx2OAHEgc6qrsKRw5Ho=";
  };
  dontBuild = true;
  dontStrip = true;
  dontPatchELF = true;
  installPhase = ''
    install -Dm755 bin/opencode $out/bin/opencode
  '';
  meta.mainProgram = "opencode";
})
