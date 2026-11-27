# omni

dendritic nix flake for three hosts: a microvm test bed, the macbook via nix-darwin (hostname `anti`), and devil — the nixos basis for the kata pod image on the talos cluster. flake-parts + import-tree, one flake, no shims. use home manager for as much as possible. microvm.nix for testing and developing. put as much as possible in XDG_CONFIG, i.e. i don't want zimfw to go in HOME somewhere but rather it should come from .config/zsh or something. the config generated for nushell from HM should `use` (or import or whatever) a dir .config/nushell/user/ so that i can add custom configuration dynamically at runtime without reswitching HM.

- openvpn (?)
- tailscale (?)

nixos only

- podman

## Starship

configured through HM. these settings apply to zsh and nushell.

shell

```
$USER@$HOSTNAME:$PWD        #(x$SHLVL) [ERR] GIT NOW
SYM
```

Zed or Rex (compact)

```
SYM     #(x$SHLVL) [ERR] GIT
```

GIT

```
[git_status]
up_to_date = "="
ahead = ">${count}"
behind = "<${count}"
diverged = ">${ahead_count}<${behind_count}"
untracked = "%${count}"
stashed = "\\$${count}"
conflicted = "!${count}"
modified = "*${count}"
staged = "+${count}"
deleted = "-${count}"
renamed = "~${count}"


[git_state]
rebase = "REBASE"
merge = "MERGE"
revert = "REVERT"
cherry_pick = "CHERRY"
bisect = "BISECT"
am = "AM"
am_or_rebase = "AM/REBASE"
```

## nix

- lix
- nom
- nh
- comma
- nix-search-cli
- direnv, nix-direnv
- nix-tree
- sops-nix
- microvm.nix
- manix
- any-nix-shell -> shell to custom zsh
- nix-du
- nvd

## apps (GUI) darwin only

- zed
- ghostty
- spotify
- whatsapp
- signal
- orbstack
- prusaslicer
- stats
- raycast
- proton*

## tools

- nh
- comma
- nom
- any-nix-shell
- lix
- git
- delta
- tea
- glab
- gh
- neovim
- helix
- zsh (zimfw)
- nushell (`use user *`)
- zoxide
- direnv
- rg
- fd
- bat
- eza
- bottom
- television
- uv
- dust
- tlrc
- age
- sops
- lua
- deno
- dysk?
- procs
- sd
- atuin
- lazydocker
- lazygit

## layout

```
flake.nix                 inputs + mkFlake + import-tree, nothing else
.sops.yaml                sops rules; encrypted files carry the .sops. pre-extension
secrets/                  data, not a module — consumed by features/home/secrets.nix + hosts/devil.nix (system-side sops)
.zed/settings.json        project settings: direnv-loaded devshell env (nil from the devshell), nixfmt on save
modules/                  import-tree root; every .nix here is a flake-parts module
├── flake/                flake-specific config (flake outputs only)
│   ├── parts.nix         systems
│   ├── devshell.nix      devShells.default (lix-built nil + nixfmt), formatter
│   ├── lix.nix           flake.overlays.lix — binds the nix tool ecosystem to lixPackageSets.stable
│   └── homes.nix         standalone homeConfigurations (bf@host) — derived from the OS hosts, for `nh home switch`
├── system/               cross-host OS classes + identity
│   ├── user.nix          user identity (flake.username)
│   ├── linux.nix         flake.modules.nixos.default — the shared NixOS class (hm wiring, lix, zsh gotchas, no channels)
│   ├── darwin.nix        flake.modules.darwin.default — the shared darwin class
│   └── macos.nix         macOS settings: Dock, empty desktop, lock screen, Finder Quit, hushlogin
├── features/
│   └── home/             the home-manager class tree, exported as flake.modules.homeManager.*
│       ├── default.nix   aggregator: imports all classes, home.stateVersion lives here
│       ├── shell.nix     zsh (zimfw), nushell (`use user *`), starship, bat as pager, zoxide, direnv, atuin
│       ├── tools.nix     rg fd bat eza bottom television uv carapace yazi lazygit + dust yq tlrc age sops lua
│       ├── theme.nix     ANSI colours only (bat, delta, LS_COLORS, both command lines)
│       ├── git.nix       git delta tea glab gh
│       ├── editor.nix    neovim (nvf); Zed user settings (vim mode, editor, layout, format on save via LSP); Zed as plain-text app (darwin)
│       ├── nix.nix       nh comma nom any-nix-shell, nix.settings, lix as nix.package
│       ├── gpg.nix       gpg identity (sops) + commit/tag signing
│       ├── ghostty.nix   ghostty (macOS: HM owns the config, the app comes from the cask)
│       ├── ssh.nix       ssh keys (public in-tree, private via sops), host entries (git :22, devil over Tailscale SSH), no agent forwarding
│       ├── rex.nix       Rex CLI everywhere (the flake's package, macOS too); init.lua lists devil (ssh://devil)
│       ├── agents.nix    agents.md for opencode and Claude Code (~/.config/claude), model keys from sops
│       ├── xdg.nix       tools moved out of ~ (kube, npm, vibe, atuin logs, nix profile links)
│       └── secrets.nix   sops-nix HM module + age key location
└── hosts/                self-contained host files; they call nixosSystem/darwinSystem themselves
    ├── vm.nix            nixosConfigurations.vm + packages.vm (microvm runner)
    ├── devil.nix         nixosConfigurations.devil + packages.devil (rootfs tarball); opencode + Claude Code
    ├── _opencode.nix     the opencode v2 build for devil (npm @opencode/cli; nixpkgs lags)
    ├── _sandbox.nix      agent-sandbox (bubblewrap): no sudo, no keys, no way out to Rex or systemd
    └── anti.nix          darwinConfigurations.anti
```

## XDG: what stays in ~

Everything that can move lives under `~/.config`, `~/.cache`, `~/.local`
(`features/home/xdg.nix`). These stay, because the tool has no setting for it
or must find them before any config is read:

| Path                   | Why                                                                     |
| ---------------------- | ----------------------------------------------------------------------- |
| `.ssh`, `.gnupg`       | keys; ssh has no XDG setting, gpg stays by choice                       |
| `.zshenv`              | zsh reads it before `ZDOTDIR` is known; it only sets `ZDOTDIR`          |
| `.hushlogin` (anti)    | `login(1)` looks for it in ~ only                                       |
| `.zed_server` (devil)  | Zed remote puts its server binary there; no setting                     |
| `.agents/skills`       | the shared agent skills directory (Rex skill); no setting               |
| `.orbstack` (anti)     | OrbStack's own state; `.docker` stays too (OrbStack's docker context)   |
| `Library`, `.Trash`    | macOS                                                                   |
| `.nix-profile`, `.nix-defexpr` (anti) | the lix installer owns `/etc/nix/nix.conf`; bf is not trusted |

After a switch, move or delete the old copies by hand: `~/.claude` and
`~/.claude.json` to `~/.config/claude/` (`.claude.json` inside it),
`~/.vibe` to `~/.config/vibe`; delete `~/.kube/cache`, `~/.npm`, `~/.atuin`,
devil's `~/.nix-defexpr` and `~/.nix-profile`, and its stale `~/.terminfo` (devil has
ghostty's terminfo system-wide).

classes contribute one module each to `flake.modules.{nixos,darwin,homeManager}`; hosts compose a class with host facts (the platform string is declared once per host); `homes.nix` derives a standalone home per host, so `nh home switch` works on every machine.

## bootstrap

### macbook (`anti`)

Moving from the old MacBook (`echo`): `docs/MIGRATION.md` lists what can move (macOS settings, casks, fonts, configs, data). The order of the day: `docs/RESET.md`.

On a fresh Mac, in Terminal.app (the setup assistant done, FileVault on):

```sh
curl -fsSL https://raw.githubusercontent.com/bfeitknecht/omni/master/install.sh | sh -s -- anti
```

`install.sh` checks the machine (macOS, Apple silicon, not root, a known
host, network, FileVault), lists the manual steps, then sets the Mac's names,
installs the Xcode Command Line Tools, Lix (its own installer, with its own
output), asks for the age key (hidden input) if `~/.config/sops/age/keys.txt`
is missing, clones omni to `~/Projects/omni`, trusts the internal CA
(`certs/internal-ca.crt`, System keychain) and runs the first switch with the
nix-darwin that `flake.lock` pins. Each step is skipped when it is done, so a
re-run is safe. `--dry-run` prints the commands without running them.

From then on, from anywhere: `nh darwin switch`.

New machine with a new age key instead of the shared one: `secrets/README.md`.

### vm — the microvm test bed (on a NixOS host, e.g. the orbstack nixos vm)

```nu
git clone https://github.com/bfeitknecht/omni.git ~/Projects/omni
cd ~/Projects/omni
nix run .#vm                    # console autologin; TCG when /dev/kvm is missing
```

The guest shares the host /nix/store read-only with a writable tmpfs overlay,
so inside the vm: clone omni, `nh os switch .#vm`. Iterate on the host,
`nix run .#vm` again. QMP control socket: `/var/tmp/omni-vm.qmp`.

### devil — the kata pod image

```nu
# bootstrap only; day-to-day updates are `nh os switch` from inside the pod.
# x86_64-linux (amd64, rzbl) since 2026-11-23; the arm64 line for the Pi is
# gone. Any linux/amd64 nix builder works; from the Mac, an OrbStack
# `nixos/nix` container builds it (everything else substitutes).
nix build .#devil
cp -L result/tarball/nixos-system-x86_64-linux.tar.xz .private/devil.tar.xz   # result points into the build host's nix store — dereference it
docker import --platform linux/amd64 .private/devil.tar.xz ghcr.io/bfeitknecht/devil:latest   # run where the docker daemon lives (OrbStack: on the mac)
docker push ghcr.io/bfeitknecht/devil:latest
```

The image is only the bootstrap (the entrypoint lives in the infra tree's
`applications/devil/deployment.yaml` as `command: ["/init"]`). Inside the
booted pod: clone omni, `nh os switch .#devil` — day-to-day
updates never touch the image. Access is tailnet only, no sshd (since
2026-11-24): **ssh** is Tailscale SSH on devil's own node `devil` (`ssh bf@devil`,
no key: the tailnet policy admits bf's own Macs and phones; Zed remote and ish
use it too) and **Rex** (sessions on the VM's personal Rex server, tailnet node
`deviler`). Break-glass: `kubectl exec` into the pod. No browser terminal: the
ghostty-web page was removed 2026-11-20.

## deferred

- starship prompt (spec above) — both shells, two TOML documents under
  `~/.config/starship/`
- podman (nixos only), openvpn/tailscale — undecided
