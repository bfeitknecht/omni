{ inputs, ... }:
let
  # The isolated OpenCode server (infra applications/opencode, a Kata VM on
  # rzbl) runs this image. infra pins this flake in images/opencode/flake.lock
  # and its CI builds and pushes the image with the infra release tag.
  system = "x86_64-linux";
  pkgs = import inputs.nixpkgs {
    inherit system;
    # claude-code is the only unfree package
    config.allowUnfreePredicate = pkg: inputs.nixpkgs.lib.getName pkg == "claude-code";
  };
  inherit (pkgs) lib;

  # OpenCode v2 (npm @opencode/cli; opencode-ai stays on 1.x). The prebuilt
  # Bun binary needs only glibc. It is not patched: patchelf would break the
  # bundle Bun appends to the file. The image links the FHS loader instead;
  # on devil, nix-ld provides it.
  opencode = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "opencode";
    version = "2.4.0";
    src = pkgs.fetchurl {
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
  });

  # The opencode-sandbox plugin: every bash command the agent runs goes
  # through bubblewrap. patch.mjs adds enableWeakerNestedSandbox (a Kata
  # container cannot mount a fresh /proc); the build fails if it does not
  # apply. Peers (@opencode/plugin) are types only: --legacy-peer-deps.
  opencode-sandbox = pkgs.buildNpmPackage {
    pname = "opencode-sandbox";
    version = "0.7.0";
    src = ./opencode/sandbox;
    npmDepsHash = "sha256-7/Tfy6kli7xa8fpu3seIK/0k563booGa91Ut8XNrls4=";
    npmFlags = [ "--legacy-peer-deps" ];
    dontNpmBuild = true;
    postInstall = ''
      ${lib.getExe pkgs.nodejs} ${./opencode/patch.mjs} \
        $out/lib/node_modules/opencode-sandbox-pin/node_modules/opencode-sandbox/dist/v2.js
    '';
  };

  # uid 1000 (node), the owner of the PVC home. Single-user nix: the whole
  # image, /nix included, belongs to node, so `nix develop` works without a
  # daemon or root.
  passwd = pkgs.runCommand "opencode-passwd" { } ''
    mkdir -p $out/etc
    echo 'root:x:0:0:root:/root:/bin/sh' > $out/etc/passwd
    echo 'node:x:1000:1000:node:/home/node:/bin/bash' >> $out/etc/passwd
    echo 'nobody:x:65534:65534:nobody:/:/bin/false' >> $out/etc/passwd
    echo 'root:x:0:' > $out/etc/group
    echo 'node:x:1000:' >> $out/etc/group
    echo 'nobody:x:65534:' >> $out/etc/group
    echo 'hosts: files dns' > $out/etc/nsswitch.conf
  '';

  nixConf = pkgs.writeTextDir "etc/nix/nix.conf" ''
    experimental-features = nix-command flakes
    # single user, inside the Kata VM: no build users, no build sandbox
    build-users-group =
    sandbox = false
    use-xdg-base-directories = true
  '';

  # Everything the image runs outside the bash sandbox: the server, the
  # plugin and its bwrap/socat/rg, git (snapshots), Claude Code, the MCP
  # servers, the loader.
  contents = [
    pkgs.dockerTools.caCertificates
    pkgs.dockerTools.usrBinEnv
    pkgs.dockerTools.binSh
    passwd
    nixConf
    opencode
    pkgs.claude-code
    pkgs.lixPackageSets.stable.lix
    # the sandbox runtime: bubblewrap, socat (network bridge), ripgrep
    pkgs.bubblewrap
    pkgs.socat
    pkgs.ripgrep
    # a base shell for the agent; project tools come from flakes
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.findutils
    pkgs.diffutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.gnutar
    pkgs.gzip
    pkgs.xz
    pkgs.less
    pkgs.procps
    pkgs.which
    pkgs.curl
    pkgs.jq
    pkgs.git
    pkgs.nodejs_22
    # MCP servers for the bot (configured in infra opencode.json)
    pkgs.mcp-nixos
    pkgs.forgejo-mcp
  ];

  # The bash sandbox policy (the plugin reads OPENCODE_SANDBOX_CONFIG_PATH).
  # Writes: the project, /tmp and single-user nix (/nix and nix's caches),
  # but never a path the image ships: the store owner is node, and those
  # paths run unsandboxed (server, plugin, Claude Code, MCP servers), so
  # every one of them is write-denied. Reads: secrets, opencode's state with
  # the API keys, the Claude login. Network: the domain allowlist (infra's
  # CiliumNetworkPolicy must allow the same names).
  sandboxPolicy =
    let
      closure = pkgs.closureInfo { rootPaths = contents ++ [ opencode-sandbox ]; };
      home = "/home/node";
      base = {
        mode = "enforce";
        filesystem = {
          denyRead =
            map (p: "${home}/${p}") [
              ".ssh"
              ".gnupg"
              ".aws/credentials"
              ".azure"
              ".config/gcloud"
              ".config/gh"
              ".kube"
              ".docker/config.json"
              ".npmrc"
              ".netrc"
              ".env"
              ".local/share/opencode"
              ".config/opencode"
              ".claude"
              ".claude.json"
            ]
            ++ [
              "/etc/opencode-providers"
              "/etc/opencode-git"
            ];
          allowWrite = [
            "\${directory}"
            "\${worktree}"
            "\${tmpdir}"
            "/nix/store"
            "/nix/var/nix"
            "${home}/.cache/nix"
            "${home}/.local/state/nix"
          ];
          denyWrite = [
            "/opt"
            "/etc"
          ];
        };
        network.allowedDomains = [
          "registry.npmjs.org"
          "*.npmjs.org"
          "registry.yarnpkg.com"
          "pypi.org"
          "*.pypi.org"
          "files.pythonhosted.org"
          "crates.io"
          "*.crates.io"
          "proxy.golang.org"
          "sum.golang.org"
          "github.com"
          "*.github.com"
          "codeload.github.com"
          "*.githubusercontent.com"
          "git.0xbf.ch"
          "cache.nixos.org"
          "channels.nixos.org"
          "releases.nixos.org"
          "tarballs.nixos.org"
        ];
      };
    in
    pkgs.runCommand "opencode-sandbox.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
      jq -n --argjson base ${lib.escapeShellArg (builtins.toJSON base)} \
        --rawfile paths ${closure}/store-paths \
        '$base | .filesystem.denyWrite += ($paths | split("\n") | map(select(length > 0)))' > $out
    '';

  image = pkgs.dockerTools.buildLayeredImage {
    name = "ghcr.io/bfeitknecht/opencode";
    tag = "dev";
    uid = 1000;
    gid = 1000;
    uname = "node";
    gname = "node";
    includeNixDB = true;
    inherit contents;
    fakeRootCommands = ''
      mkdir -p lib64 tmp home/node/Projects opt/opencode-sandbox etc/claude-code
      chmod 1777 tmp
      # the FHS loader for the prebuilt OpenCode binary
      ln -s ${pkgs.glibc}/lib64/ld-linux-x86-64.so.2 lib64/ld-linux-x86-64.so.2
      # loaded by file:// URL from infra opencode.json (directory form; v2
      # resolves the package entry dist/v2.js). A root-owned copy, not a
      # link: OpenCode watches the plugin and reloads it on change, and the
      # store belongs to node.
      cp -rL ${opencode-sandbox}/lib/node_modules/opencode-sandbox-pin/node_modules opt/opencode-sandbox/node_modules
      cp ${sandboxPolicy} etc/opencode-sandbox.json
      # Claude Code's own bash sandbox, the same deny-read rules and domain
      # allowlist as the plugin, no bypass mode
      cp ${./opencode/claude-managed-settings.json} etc/claude-code/managed-settings.json
      # Single-user nix and the home belong to node. The store paths come in
      # with uid 1000 (above); this layer holds /nix/store itself and the db.
      # /opt and /etc/claude-code stay root's: the agent cannot edit them.
      chown -R 1000:1000 nix home
    '';
    config = {
      User = "1000:1000";
      WorkingDir = "/home/node";
      Env = [
        "PATH=/bin:/usr/bin"
        "HOME=/home/node"
        "USER=node"
        "TMPDIR=/tmp"
        "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        "NIX_SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt"
        # no updater, no telemetry
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1"
        # the bash sandbox policy (root-owned, built above)
        "OPENCODE_SANDBOX_CONFIG_PATH=/etc/opencode-sandbox.json"
      ];
      # serve is the v2 server command; it serves the web UI too
      Cmd = [
        "opencode"
        "serve"
        "--hostname"
        "0.0.0.0"
        "--port"
        "4096"
      ];
      ExposedPorts."4096/tcp" = { };
    };
  };
in
{
  flake.packages.${system} = {
    inherit opencode opencode-sandbox;
    opencode-sandbox-policy = sandboxPolicy;
    opencode-image = image;
  };
}
