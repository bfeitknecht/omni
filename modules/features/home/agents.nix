{
  # Every agent session (opencode, Claude Code) on every host gets the same
  # setup: one instruction file (agents.md; infra's opencode pod fetches the
  # same file from this repo), the model providers, the MCP servers.
  flake.modules.homeManager.agents =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      providers = [
        "anthropic"
        "mistral"
        "openrouter"
      ];
    in
    {
      xdg.configFile."opencode/AGENTS.md".source = ./agents.md;
      home.file.".claude/CLAUDE.md".source = ./agents.md;

      # API keys: sops renders each to a file; opencode reads it at start
      # ({file:...}), so no key sits in an env var a command could print.
      # Same keys as infra opencode-providers (the pod).
      sops.secrets = lib.genAttrs (
        map (p: "opencode/${p}") providers
        ++ [
          "mcp/github"
          "mcp/forgejo"
        ]
      ) (_: { });

      xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        providers = lib.genAttrs providers (p: {
          settings.apiKey = "{file:${config.sops.secrets."opencode/${p}".path}}";
        });
        mcp.servers = {
          # shell history search (the encrypted history synced from atuin.0xbf.ch)
          atuin = {
            type = "local";
            command = [
              (lib.getExe config.programs.atuin.package)
              "mcp"
            ];
          };
          # nixpkgs, NixOS and Home Manager options, package versions
          nixos = {
            type = "local";
            command = [ (lib.getExe pkgs.mcp-nixos) ];
          };
          # GitHub as bf (fine-grained token; the repos there are mirrors of
          # Forgejo, so mostly reading: issues, PRs, Actions runs)
          github = {
            type = "local";
            command = [
              (lib.getExe pkgs.github-mcp-server)
              "stdio"
            ];
            environment.GITHUB_PERSONAL_ACCESS_TOKEN = "{file:${config.sops.secrets."mcp/github".path}}";
          };
          # Forgejo (git.0xbf.ch) as bf: repos, issues, PRs, releases
          forgejo = {
            type = "local";
            command = [
              (lib.getExe pkgs.forgejo-mcp)
              "--transport"
              "stdio"
              "--url"
              "https://git.0xbf.ch"
            ];
            environment.FORGEJO_ACCESS_TOKEN = "{file:${config.sops.secrets."mcp/forgejo".path}}";
          };
        };
      };
    };
}
