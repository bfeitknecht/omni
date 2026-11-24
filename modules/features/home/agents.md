# Global agent instructions

These rules apply to every agent session on my machines (opencode, Claude Code).
A project's own `AGENTS.md` or `CLAUDE.md` adds to them and wins where it differs.

## Tools come from Nix flakes

- Every project gets its tools from its own `flake.nix` (`devShells.default`) and
  `flake.lock`. Use `nix develop`, or `direnv` with `use flake` in `.envrc`. Commit
  `flake.nix`, `flake.lock` and `.envrc`.
- If a project has no flake and needs tools, create a minimal one first. Pin with
  the lock file, not with version strings in scripts.
- Never install tools globally or into my home: no `brew install`, `npm -g`,
  `pip install --user`, `cargo install`, `go install`, `curl … | sh`, `apt`, no
  edits to my shell profile. My system config lives in omni and only I change it.
- A tool for one command: `nix run nixpkgs#<tool> -- …` or `nix shell nixpkgs#<tool>`.
- If `nix` is not available, say so and stop. Do not fall back to a global install.

## Keep the tree clean

- Write only inside the project. No stray files in `$HOME`, no scratch files in the
  repo. Build output and caches go in `.gitignore`d paths.
- Add a dependency only when it earns its place. Prefer the standard library.
  Say why when you add one.
- Do not commit, push, tag or delete branches unless I ask.

## Modern, sane defaults

- Search: `rg`, `fd`. JSON: `jq`. Git diffs: `git diff`, not ad-hoc scripts.
- Python: `uv` (`uv run`, `uv add`, `pyproject.toml` + `uv.lock`), Python from the flake.
- JavaScript and TypeScript: the package manager the project already uses (lock
  file present); for a new project `pnpm`. TypeScript `strict`.
- Rust: `cargo` from the flake, `clippy` and `rustfmt` clean.
- Shell scripts: POSIX `sh` or `bash` with `set -euo pipefail`, `shellcheck` clean.
  Commands for me to type: nushell syntax.
- Format and lint with the project's tools before you say you are done. Run the
  tests that exist. Report what you ran and what failed.

## Writing

- Short sentences. Plain words. No filler, no marketing tone.
- Comments say why, not what.
