# Roadmap

Status as of 2026-11-27. omni is the nix lane: one dendritic flake for the MacBook Pro (`anti`, the daily driver), the devil Kata VM on the talos cluster (x86_64-linux on rzbl) and a microvm test bed. The cluster side is `infra/ROADMAP.md`.

## Where things stand

- Flake: flake-parts + import-tree, lix overlay, home-manager as the config carrier, sops-nix for secrets. Classes in `modules/system/{linux,darwin,macos}.nix`; hosts compose class + host facts; standalone homes derive from the hosts (`nh home switch`).
- Home modules: shell (zsh/zimfw + nushell `use user *`, starship), tools, theme (ANSI only), git (delta, tea, gh, glab), editor (nvf; Zed settings), nix tooling, gpg, ssh (per-service keys, Tailscale SSH to devil and anti over `tailscale nc`, no agent forwarding), Rex, agents (`agents.md`, model keys from sops), xdg (tools out of ~), ghostty.
- `anti` (darwin): live since 2026-11-25. Dock, empty desktop, no lock screen clock, Finder Quit, hushlogin, Ghostty and Zed riced (2026-11-27). Tailscale is the open-source tailscaled (`tag:anti`) for its Tailscale SSH server; no app.
- `devil` (NixOS, Kata VM): Tailscale SSH only (`tag:devil`), Rex server over `ssh://devil` (no Rex tailnet node), opencode and Claude Code inside agent-sandbox (`hosts/_sandbox.nix`: no sudo, no keys, no Rex, no tailnet).
- `vm`: the microvm test bed (aarch64-linux on the Mac).

## NOW

- [ ] **CLI logins** by hand: `gh`, `tea`, `glab` on devil; `gh`, `tea` on anti. Tokens are not declarative on purpose.
- [ ] **Rex on the phone:** host `ssh://bf@devil` works; then delete the node `iotar` in the Tailscale admin console.
- [ ] **Back up the age key** (`~/.config/sops/age/keys.txt`) off the Mac (Proton Pass). It decrypts omni and infra.

## NEXT — rice on anti (one piece per `nh darwin switch`)

- [ ] **Tiling:** dinky (`mikker/tap/dinky` cask: `homebrew.taps` + `casks`; no SIP change) or AeroSpace (`services.aerospace`).
- [ ] **Bar:** sketchybar (`services.sketchybar`), menu bar auto-hide (`AutoHideMenuBarOption`).
- [ ] **Borders:** jankyborders (`services.jankyborders`).
- [ ] **Launcher:** tuna or Raycast (cask).
- [ ] **Keys:** kindavim (cask), karabiner into nix (`karabiner.json` via `xdg.configFile`), ukulele (layout), hammerspoon (cask).
- [ ] **Look:** dark mode, Liquid Glass (`NSGlassDiffusionSetting`), window animations off, a dynamic (light/dark) wallpaper, stats (cask) or not.
- [ ] **Dock:** position, size, hot corners (`wvous-*-corner`).
- [ ] **App Store apps** (`homebrew.masApps`; needs the App Store login).

## LATER

- [ ] **Agents drive Rex** — agent-sandbox hides the Rex socket today: a Rex session runs outside the sandbox, so Rex access is a way out (to the age key, sudo). Needs a Rex permission scope (sessions for the agent only) or the agents as their own user with their own Rex server.
- [ ] **Configure nvf** — deeper neovim config in `editor.nix`.
- [ ] **Make devil nicer** — shell and editor parity inside the VM.
- [ ] **Expose apps/tools from the flake** — `packages`/`apps` outputs (nvim, home) runnable without a host switch.
- [ ] `use-xdg-base-directories` in the home nix.conf warns on devil (bf is not trusted); the system nix.conf has it already. Drop it from the home side once HM's profile path is checked.
- [ ] vm stays the nixos iteration loop: stage devil changes in the microvm before the real VM.

## SOMEDAY

podman on devil (undecided), starship polish.

## Conventions

- As little global config as possible; per-project overrides (`.zed/settings.json`, direnv) beat global knobs.
- XDG over HOME dotfiles (README: what stays in ~); nushell user config stays runtime-extensible (`use user *`).
- Secrets only via sops-nix; never bake values into the flake.
- Switches via `nh` (`nh darwin switch`, `nh os switch`); lix is the system nix everywhere.
