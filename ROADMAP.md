# Roadmap

Status as of 2026-10-14. omni is the nix lane: one dendritic flake feeding the macbook (`auto`), the devil kata-pod image on the talos cluster, and a microvm test bed. The cluster-side counterpart lives in `infra/ROADMAP.md` — the two lanes touch at exactly two gates: the **devil deploy** and the **macbook reset**.

## Where things stand

- Flake shape is settled: flake-parts + import-tree, lix overlay binding the nix tool ecosystem, home-manager as the config carrier, sops-nix for secrets.
- Home modules landed: shell (zsh/zimfw + nushell `use user *`), tools, git (delta/jujutsu/tea/gh), editor (nvf + helix), nix tooling (nh/comma/nom/any-nix-shell), gpg identity (sops), sops secrets class.
- Starship prompt landed for both shells (polish ongoing); atuin and pay-respects wired into the shell; git identity, ssh keys + new SOPS recipient in.
- Hosts: `auto` (darwin — nix-homebrew owns brew, zed + ghostty casks active, the rest of the cask list still commented out), `devil` (NixOS docker-container tarball → kata pod image, aarch64), `vm` (microvm test bed, console autologin, shared host store + writable overlay).
- The macbook is still the pre-nix daily driver; the factory reset is gated on the parity work below.
- TODO residue already done: gpg identity (`gpg.nix`), starship, ssh keys — prunable from `.private/TODO.md`.

## The two gates

1. **Age key backup** — `~/.config/sops/age/keys.txt` leaves the machine before anything else moves. sops-managed state in omni (and possibly infra) hangs off it.
2. **Devil deploy** — the image only matters once the infra-side deploy lands (infra ROADMAP, NOW queue).

## NOW — pre-reset parity (macbook)

Ordered; the factory reset happens only after all of these:

- [ ] **Back up the age key** (`~/.config/sops/age/keys.txt`) — before any transfer, full stop.
- [ ] **Zed settings → nix** (layout, theme, extensions) — as little global config as possible; per-project `.zed/settings.json` for lsp/formatter/debugger/tasks.
- [ ] **macOS defaults → nix-darwin** `system.defaults`: dock (autohide, show speed), finder (quittable), wallpaper, liquid-glass styling.
- [ ] **Brewfile parity** — un-comment the casks actually in use (spotify, whatsapp, signal, orbstack, prusaslicer, stats, raycast, proton-*) so the reset restores app parity.
- [ ] FileVault is enabled manually during the reset (not declarable via nix-darwin).

Then: factory reset → bootstrap per the README runbook (lix installer → xcode-select → clone → first switch → secrets) → iterate with `nh darwin switch`.

## NEXT — devil (pairs with the infra deploy)

- [x] **Teleport-only access (decided)** — devil ships **no sshd at all**; the image runs a teleport agent (`ssh_service`) that dials the cluster's teleport proxy. Connecting = be on the tailnet, `tsh login --proxy teleport.internal`, `tsh ssh bf@devil`. No Service, no HTTPRoute — nothing dials in.
- [ ] **Join token** — `tctl tokens add --type=node` on the teleport cluster → sops into infra as `devil-teleport-token` (Secret in the `devil` namespace), mounted at `/run/secrets/teleport-token`; the agent's `--token` reads the file.
- [ ] **State preservation decision** — the pod rootfs is the image: either bake-and-repush on every change (rebuild → `docker import` → push → roll) or PVC-back `/nix` + state so in-pod `nh os switch` survives restarts. This decision shapes everything else about devil.
- [ ] **Make devil nicer** — shell/editor parity inside the pod (it already imports the full home config).
- ghostty-web will ride teleport **app access** (`app_service` in devil's agent config) once it exists — which also retires the old "split devil ingress" TODO: there is no devil ingress to split. Infra-side steps (build/import/push, kata pod deploy) are tracked in `infra/ROADMAP.md` NOW.

## LATER — rice & iteration (post-reset)

- [ ] Rice: sketchybar, yabai, dinky, jankyborder, tuna launcher, kindavim — one piece at a time, each behind `nh darwin switch`.
- [ ] **Configure nvf** — deeper neovim config in `editor.nix`.
- [ ] **Expose apps/tools from the flake** — `packages`/`apps` outputs (nvim, home) runnable without a host switch.
- [ ] vm stays the nixos iteration loop: stage devil changes in the microvm (same aarch64-linux platform, same home config) before touching the real pod.

## SOMEDAY

podman (nixos only), openvpn/tailscale on devil (undecided in the README), starship polish, whatever the rice list grows into.

## Conventions

- As little global config as possible; per-project overrides (`.zed/settings.json`, direnv) beat global knobs.
- XDG_CONFIG over HOME dotfiles; nushell user config stays runtime-extensible (`use user *`).
- Secrets only via sops-nix; never bake values into the flake.
- Switches via `nh` (`nh darwin switch`, `nh os switch`); lix is the system nix everywhere.
