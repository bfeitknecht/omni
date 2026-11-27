# Roadmap

Status as of 2026-11-27. omni is the nix lane: one dendritic flake feeding the MacBook Pro (`anti`), the devil Kata VM on the talos cluster (x86_64-linux on rzbl), and a microvm test bed. The cluster-side counterpart lives in `infra/ROADMAP.md`.

## Where things stand

- Flake shape is settled: flake-parts + import-tree, lix overlay, home-manager as the config carrier, sops-nix for secrets. Classes live in `modules/system/{linux,darwin}.nix`; hosts compose class + host facts; standalone homes derive from the hosts (`nh home switch` on every host).
- Home modules: shell (zsh/zimfw + nushell `use user *`), tools (incl. `yq-go`), git (delta, tea, gh, glab; jujutsu removed 2026-11-25), editor (nvf + helix), nix tooling, gpg identity, ssh (per-service keys; `devil` over Tailscale SSH), agents (`agents.md` for opencode and Claude Code, model keys from sops, no MCP servers), Rex, xdg (tools out of ~).
- Hosts: `anti` (darwin), `devil` (NixOS, Kata VM image, x86_64-linux; access only by Tailscale SSH, tailnet node `devil`; Rex node `deviler`; no sshd), `vm` (microvm test bed).
- No images (removed 2026-11-27). devil has its own opencode build (`hosts/_opencode.nix`).
- The old MacBook (`echo`) is still the daily driver; the move to `anti` is gated on the parity work below. What can move: `docs/MIGRATION.md`.

## The two gates

1. **Age key backup** — `~/.config/sops/age/keys.txt` leaves the machine before anything else moves. sops-managed state in omni (and possibly infra) hangs off it.
2. **Devil deploy** — the image only matters once the infra-side deploy lands (infra ROADMAP, NOW queue).

## NOW — echo -> anti (reset the night of 2026-11-25)

The first switch is a minimal known-good baseline; rice follows one piece at a time. Runbook: `docs/RESET.md`.

- [x] **Reset runbook** — `docs/RESET.md`: the baseline (A), the last hour on echo (B), day one on anti (C).
- [x] **macOS settings** — function only (Finder Quit, screenshots, trackpad, typing, Touch ID sudo), `modules/system/macos.nix`. Dock, menu bar, look: iterate after the reset (echo's set in `docs/MIGRATION.md`).
- [x] **Casks** — the owner's list in `anti.nix`.
- [x] **Zed** — vanilla + CommitMono, default theme (`features/home/editor.nix`).
- [x] **Colours** — ANSI only in shells (zsh highlighting, nushell) and CLI tools (bat, delta, vivid LS_COLORS); frontends theme them (`features/home/theme.nix`).
- [x] **Tools** — carapace, lazygit, lazydocker, lazysql, yazi (bat previews), uutils coreutils; helix off.
- [x] **Wallpaper** — apex `brand/wallpaper.typ` (NULL, light and dark), set by `install.sh`.
- [x] **Repos in `~/Projects/<name>`** on every host; nh flake default `~/Projects/omni`.
- [ ] **Back up the age key** (`~/.config/sops/age/keys.txt`) — before the erase, full stop.
- [ ] FileVault on in the setup assistant (not declarable).
- [ ] After the first switch: Finder and trackpad after a re-login, `sudo` with Touch ID.

## NEXT — devil

Done and live: Kata VM on rzbl, `/nix` on the PVC, Tailscale SSH only (2026-11-24), Rex server, opencode and Claude Code as bf inside agent-sandbox (`hosts/_sandbox.nix`: no sudo, no keys). The history (sshd, ghostty-web, Teleport) is in git and in `infra/docs/journey.md`.

- [ ] **Make devil nicer** — shell/editor parity inside the VM (it already imports the full home config).
- [ ] **Forge CLI logins** — `gh`, `tea`, `glab` by hand on devil and anti (atlas `cli-logins`; tokens are not declarative on purpose).

## NOW — light rice on anti (2026-11-27, waits for `nh darwin switch`)

- [x] Dock: Finder, Settings, Ghostty, Zed, Spotify; no recents, no folders.
- [x] Empty desktop (no icons, no widgets); Finder Quit (Cmd-Q; one logout after the first switch).
- [x] Lock screen without the large clock (`UsesLargeDateTime`; not verified on macOS 26, the UI fallback is in `macos.nix`).
- [x] Ghostty: no title bar or buttons, padding, steady block cursor, faded unfocused splits, copy on select, gamma-correct text.
- [x] Zed: vim mode, format on save via LSP, terminal copy on select; Zed is the plain-text app (Cmd-, in Ghostty).
- [x] hushlogin; starship error status bold red; bat pages only when needed, no STDIN header.
- [x] Tools out of ~ (`features/home/xdg.nix`): Claude Code, Vibe, kube, npm, atuin logs, nix profile links.
- [x] Old Zed settings: the editor group, tabs, tab bar, git panel left, no search or collaboration button, terminal without badge, breadcrumbs, scrollbar. Not carried: theme, AI, languages.
- [x] Prompt: ASCII for deleted (`-`) and renamed (`~`), like the rest of git_status.
- [x] No ssh agent forwarding (`ssh.nix`), not even to devil.

## LATER — rice & iteration (post-reset)

- [ ] Rice: sketchybar, yabai / aerospace / dinky, jankyborders, tuna or raycast, kindavim, karabiner into nix, App Store apps (`masApps`), a dynamic (light/dark) wallpaper — one piece at a time, each behind `nh darwin switch`.
- [ ] **Configure nvf** — deeper neovim config in `editor.nix`.
- [ ] **Expose apps/tools from the flake** — `packages`/`apps` outputs (nvim, home) runnable without a host switch.
- [ ] vm stays the nixos iteration loop: stage devil changes in the microvm (same home config) before touching the real VM. Note: devil is x86_64-linux now; the microvm on the Mac is aarch64-linux.
- [x] **Teleport teardown** — done 2026-10-24 (after the friend demo): omni (agent unit, port 3022, the `TELEPORT_SESSION` prompt special-case in shell.nix) + infra (`infrastructure/teleport/`, the devil mounts/secret/configmap, `dependsOn`) + docs.

## SOMEDAY

podman on devil (undecided), starship polish, whatever the rice list grows into.

## Conventions

- As little global config as possible; per-project overrides (`.zed/settings.json`, direnv) beat global knobs.
- XDG_CONFIG over HOME dotfiles; nushell user config stays runtime-extensible (`use user *`).
- Secrets only via sops-nix; never bake values into the flake.
- Switches via `nh` (`nh darwin switch`, `nh os switch`); lix is the system nix everywhere.
