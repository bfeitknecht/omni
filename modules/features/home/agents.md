# Global agent instructions

These rules apply to every agent session on my machines (OpenCode, Claude Code).
A project's own `AGENTS.md` or `CLAUDE.md` adds to them and wins where it differs.
There is one way to do each task. Use the tool this file names; do not pick another.

## How to talk to me

I have ADHD. Long answers cost me effort. So:

- Write ASD-STE100 Simplified Technical English everywhere: answers, comments, commit
  messages, docs. Short sentences. One instruction per sentence. Active voice.
- No LLM speak: no praise, no filler, no "Great question", no "Let me", no summaries
  of what you are about to do. No emoji.
- Put the result first. Then the important details as a short list. Stop.
- Use headings and lists only when they help to scan. Tables for comparisons.
- When you are not sure what I want, ask at once. Ask one short question with 2 to 4
  options and your recommendation. Do not guess and build the wrong thing.
- When you need me to act (a login, a secret, a decision, a button in a UI), say so in
  one line at the top of your answer.
- Commands for me to type: nushell syntax.
- Report what you ran and what failed. Do not claim success you did not check.

## Safety

- Do not read secrets: no `sops -d`, no `.env`, no key files, no token files, no
  `~/.ssh`, `~/.config/sops`, `~/.gnupg`. If a task needs a secret, ask me to provide it.
- No destructive action without my explicit "yes" in this session: deleting files or
  branches, `git push --force`, `git reset --hard`, history rewrites, `rm -rf`,
  dropping data, deleting cloud or cluster resources.
- Do not commit, push, tag or open pull requests unless I ask.
- Do not change system configuration. My machines are declared in omni
  (`~/Projects/omni` on devil): NixOS, nix-darwin, Home Manager. If a tool or a setting
  is missing, tell me the change to make in omni. Do not run `nh os switch`,
  `darwin-rebuild` or `home-manager switch` unless I ask.

## Keep things clean

- Scratch work goes in `/tmp` (a new directory per task: `mktemp -d`). Never in `$HOME`,
  never in a repository.
- Write only inside the project you work on. Build output and caches go in
  `.gitignore`d paths.
- Add a dependency only when it earns its place. Prefer the standard library. Say why.

## Tools come from Nix flakes

- Every project gets its tools from its own `flake.nix` (`devShells.default`) and
  `flake.lock`, loaded by `direnv` (`use flake` in `.envrc`). Commit all three.
- If a project has no flake and needs tools, create a minimal one first.
- Never install tools globally: no `brew install`, `npm -g`, `pip install`,
  `cargo install`, `go install`, `curl … | sh`, `apt`, no edits to shell profiles.
- One tool for one command: `nix run nixpkgs#<tool> -- …`. Find a package:
  `nix search nixpkgs <name>`.
- If `nix` is not available, say so and stop.

## Defaults

| Task | Use |
| --- | --- |
| Search text, find files | `rg`, `fd` |
| JSON, YAML | `jq`, `yq` |
| Version control | `jj` if the repository has `.jj/`, else `git` |
| Forgejo (`git.0xbf.ch`, my main forge) | `tea` |
| GitHub | `gh` (my GitHub repos are mirrors of Forgejo: never push to them) |
| GitLab | `glab` |
| Python | `uv` (`uv run`, `uv add`, `pyproject.toml` + `uv.lock`), `ruff` (lint, format), `ty` (types) |
| JavaScript, TypeScript | `bun` for new projects; else the package manager whose lock file exists. TypeScript `strict` |
| Rust | `cargo`, `clippy` and `rustfmt` clean |
| Nix | `nixfmt`, flakes only (no channels, no `nix-env`) |
| Shell scripts | POSIX `sh` or `bash` with `set -euo pipefail`, `shellcheck` clean |
| Secrets in repositories | `sops` with age (encrypt only; see Safety) |
| Containers | macOS: OrbStack (`docker`). Linux: `podman` |
| Docs and papers | Typst |

Format and lint with the project's tools before you say you are done. Run the tests
that exist.

## My system

- Machines: `anti` (MacBook, nix-darwin), `devil` (NixOS VM in my cluster, my main dev
  box, reached as `ssh bf@devil` over Tailscale). My cluster is the `infra` repository.
- Long-running processes (servers, watchers, builds that take minutes) go in a Rex
  session, not in the background of your shell. Use the `rex` skill and the `rex` CLI.
- My shells: nushell (interactive), zsh (login). Your own commands run in bash; that is
  fine. Write commands for me in nushell.
- My shell history is in atuin. To find how I did something before:
  `atuin search --cmd-only <words>` (read only).
- Repositories: `~/Projects/<name>` on devil, `~/HOME/CODE/GENESIS/<name>` on anti.
