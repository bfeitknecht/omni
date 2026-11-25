# Roadmap

Status as of 2026-11-25. omni is the nix lane: one dendritic flake feeding the MacBook Pro (`anti`), the devil Kata VM on the talos cluster (x86_64-linux on rzbl), the opencode server image for the cluster, and a microvm test bed. The cluster-side counterpart lives in `infra/ROADMAP.md`.

## Where things stand

- Flake shape is settled: flake-parts + import-tree, lix overlay, home-manager as the config carrier, sops-nix for secrets. Classes live in `modules/system/{linux,darwin}.nix`; hosts compose class + host facts; standalone homes derive from the hosts (`nh home switch` on every host).
- Home modules: shell (zsh/zimfw + nushell `use user *`), tools (incl. `yq-go`), git (delta, tea, gh, glab; jujutsu removed 2026-11-25), editor (nvf + helix), nix tooling, gpg identity, ssh (per-service keys; `devil` over Tailscale SSH), agents (`agents.md` for opencode and Claude Code, model keys from sops, no MCP servers), Rex.
- Hosts: `anti` (darwin), `devil` (NixOS, Kata VM image, x86_64-linux; access only by Tailscale SSH, tailnet node `devil`; Rex node `deviler`; no sshd), `vm` (microvm test bed).
- Images: `modules/images/opencode.nix` builds the opencode server image (Nix, `dockerTools.buildLayeredImage`); infra pins this flake in `images/opencode/flake.lock`. One opencode build (`modules/images/opencode/_cli.nix`) serves the pod and devil.
- The old MacBook (`echo`) is still the daily driver; the move to `anti` is gated on the parity work below. What can move: `docs/MIGRATION.md`.

## The two gates

1. **Age key backup** — `~/.config/sops/age/keys.txt` leaves the machine before anything else moves. sops-managed state in omni (and possibly infra) hangs off it.
2. **Devil deploy** — the image only matters once the infra-side deploy lands (infra ROADMAP, NOW queue).

## NOW — pre-reset parity (macbook)

Ordered; the factory reset happens only after all of these:

**This is the next push** (owner, 2026-11-25): factory reset, apply omni. The owner has a backup of everything important in the user home.

- [x] **Reset runbook** — `docs/RESET.md` (2026-11-25): decisions first (section A), the last hour on echo (B), day one on anti (C).

- [ ] **Back up the age key** (`~/.config/sops/age/keys.txt`) — before any transfer, full stop.
- [ ] **Zed settings → nix** (layout, theme, extensions) — as little global config as possible; per-project `.zed/settings.json` for lsp/formatter/debugger/tasks.
- [ ] **macOS defaults → nix-darwin** — echo's settings are read out (2026-11-19) into `docs/MIGRATION.md` with a ready block. Pick, paste into `anti.nix`, verify on the first `nh darwin switch`.
- [ ] **Brewfile parity** — un-comment the casks actually in use (spotify, whatsapp, signal, orbstack, prusaslicer, stats, raycast, proton-*) so the reset restores app parity.
- [ ] FileVault is enabled manually during the reset (not declarable via nix-darwin).

Then: factory reset → bootstrap per the README runbook (lix installer → xcode-select → clone → first switch → secrets) → iterate with `nh darwin switch`.

## NEXT — devil

Done and live: Kata VM on rzbl, `/nix` on the PVC, Tailscale SSH only (2026-11-24), Rex server, opencode + `oc` (attach to the cluster server), Claude Code. The history (sshd, ghostty-web, Teleport) is in git and in `infra/docs/journey.md`.

- [ ] **Make devil nicer** — shell/editor parity inside the VM (it already imports the full home config).
- [ ] **Forge CLI logins** — `gh`, `tea`, `glab` by hand on devil and anti (atlas `cli-logins`; tokens are not declarative on purpose).

## LATER — rice & iteration (post-reset)

- [ ] Rice: sketchybar, yabai, dinky, jankyborder, tuna launcher, kindavim — one piece at a time, each behind `nh darwin switch`.
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
