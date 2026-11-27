{
  # Every agent session (opencode, Claude Code) on every host gets the same
  # setup: one instruction file (agents.md) and the model providers. No MCP servers on
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
      # Claude Code in ~/.config/claude, not ~/.claude and ~/.claude.json:
      # CLAUDE_CONFIG_DIR moves both (.claude.json goes inside the dir).
      xdg.configFile."claude/CLAUDE.md".source = ./agents.md;
      home.sessionVariables.CLAUDE_CONFIG_DIR = "${config.xdg.configHome}/claude";

      # API keys: sops renders each to a file; opencode reads it at start
      # ({file:...}), so no key sits in an env var a command could print.
      sops.secrets = lib.genAttrs (map (p: "opencode/${p}") providers) (_: { });

      xdg.configFile."opencode/opencode.json".text = builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        providers = lib.genAttrs providers (p: {
          settings.apiKey = "{file:${config.sops.secrets."opencode/${p}".path}}";
        });
      };
    };
}
