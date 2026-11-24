{
  # Global instructions for every agent session (opencode, Claude Code): tools
  # from Nix flakes only, a clean tree, modern defaults. One source, agents.md;
  # infra's opencode pod fetches the same file from this repo.
  flake.modules.homeManager.agents = { ... }: {
    xdg.configFile."opencode/AGENTS.md".source = ./agents.md;
    home.file.".claude/CLAUDE.md".source = ./agents.md;
  };
}
