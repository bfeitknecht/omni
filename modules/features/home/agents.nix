{
  # Every agent session (opencode, Claude Code) on every host gets the same
  # setup: one instruction file (agents.md; infra's opencode pod fetches the
  # same file from this repo) and the model providers. No MCP servers on
  # purpose: agents use the CLIs that agents.md names, one way per task.
  flake.modules.homeManager.agents =
    { config, lib, ... }:
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
      sops.secrets = lib.genAttrs (map (p: "opencode/${p}") providers) (_: { });

      xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        providers = lib.genAttrs providers (p: {
          settings.apiKey = "{file:${config.sops.secrets."opencode/${p}".path}}";
        });
      };
    };
}
