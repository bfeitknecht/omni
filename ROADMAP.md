# Roadmap

Status as of 2026-10-14. omni is the nix lane: one dendritic flake feeding the macbook (`auto`), the devil kata-pod image on the talos cluster, and a microvm test bed. The cluster-side counterpart lives in `infra/ROADMAP.md` — the two lanes touch at exactly two gates: the **devil deploy** and the **macbook reset**.

## Where things stand

- Flake shape is settled: flake-parts + import-tree, lix overlay binding the nix tool ecosystem, home-manager as the config carrier, sops-nix for secrets. Classes live in `modules/system/{linux,darwin}.nix` (`flake.modules.{nixos,darwin}.default`); hosts compose class + host facts; standalone homes derive from the hosts (`nh home switch` on every host).
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

- [x] **Keypair + login secret (owner, blocking)** — `ssh-keygen -t ed25519 -f devil -C devil`; add `ssh/devil` + `ssh/devil.pub` (ssh.nix declares both halves, like every other key) and `login/devil` (`mkpasswd -m yescrypt` of the ghostty-web login password) to `secrets/secrets.sops.yaml`. No paste step: sshd reads the pub half straight from the sops-materialized file (`AuthorizedKeysFile /run/secrets/ssh/devil.pub` — eval can't read sops, `authorizedKeys.keyFiles` is `listOf path` and forbids `/run` paths in pure eval). ⚠️ every `nh * switch` on every host fails until `ssh/devil` exists (HM sops activation); devil's additionally needs `login/devil`.
- [x] ~~**Teleport-only access**~~ — **superseded 2026-10-20: ssh + ghostty-web**. devil ships sshd (port 2222, pubkey-only, password login blocked, host keys persisted at `/var/lib/ssh` on the PVC) and the ghostty-web terminal at `devil.internal` — ttyd in the VM serves the infra-side static page (ConfigMap at `/srv/ghostty-web`) and puts a real `login` prompt on the pty: PAM validates bf's password (`login/devil`, devil-only), the shell is the full home config. The internal-allowlist middleware is the only network gate; the router forwards nothing. The teleport agent was torn down 2026-10-24 (both trees) — ssh + ghostty-web are the only doors. Infra side (gateway `devilssh` listener, headless Service, HTTPRoute + TCPRoute) lives in `applications/devil/` — the kata VM bypasses ClusterIP translation, hence the headless Service.
- [x] **Join token** — minted (`tctl tokens add --type=node`), sops'd into infra as `devil-teleport-token` (Secret in the `devil` namespace), mounted at `/etc/teleport-secrets/teleport-token`; the agent's `--token` reads the file. The CA pin is baked into the agent config (`ca_pin`). Removed 2026-10-24 with the teleport teardown.
- [x] **State preservation** — devil-pvc (infra, renamed from devil-state; subPaths `home`/`ssh` — the `teleport` subPath went with the 2026-10-24 teardown). The image is only the bootstrap; day-to-day updates are in-pod `nh os switch .#devil` (the docker-container profile keeps `/init` fresh across switches); `/nix` stays ephemeral — a re-switch from the persisted clone converges. ⚠️ the PVC rename needs the volume-copy runbook on the infra side (prune deletes the old PVC) — `infra/.private/devil-pvc-rename.md`.
- [ ] **Make devil nicer** — shell/editor parity inside the pod (it already imports the full home config).
- [x] **Build + publish the bootstrap image** — on a NixOS host: `nix build .#devil` → `docker import --platform linux/arm64` → push `ghcr.io/bfeitknecht/devil:latest` (tag is meaningless — in-machine updates), then the infra tag. Infra-side steps are tracked in `infra/ROADMAP.md` NOW.

## LATER — rice & iteration (post-reset)

- [ ] Rice: sketchybar, yabai, dinky, jankyborder, tuna launcher, kindavim — one piece at a time, each behind `nh darwin switch`.
- [ ] **Configure nvf** — deeper neovim config in `editor.nix`.
- [ ] **Expose apps/tools from the flake** — `packages`/`apps` outputs (nvim, home) runnable without a host switch.
- [ ] vm stays the nixos iteration loop: stage devil changes in the microvm (same aarch64-linux platform, same home config) before touching the real pod.
- [x] **Teleport teardown** — done 2026-10-24 (after the friend demo): omni (agent unit, port 3022, the `TELEPORT_SESSION` prompt special-case in shell.nix) + infra (`infrastructure/teleport/`, the devil mounts/secret/configmap, `dependsOn`) + docs.

## SOMEDAY

podman (nixos only), openvpn/tailscale on devil (undecided in the README), starship polish, whatever the rice list grows into.

## Conventions

- As little global config as possible; per-project overrides (`.zed/settings.json`, direnv) beat global knobs.
- XDG_CONFIG over HOME dotfiles; nushell user config stays runtime-extensible (`use user *`).
- Secrets only via sops-nix; never bake values into the flake.
- Switches via `nh` (`nh darwin switch`, `nh os switch`); lix is the system nix everywhere.
