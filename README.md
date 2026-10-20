# omni

dendritic nix flake for three hosts: a microvm test bed, the macbook via nix-darwin (hostname `auto`), and devil — the nixos basis for the kata pod image on the talos cluster. flake-parts + import-tree, one flake, no shims. use home manager for as much as possible. microvm.nix for testing and developing. put as much as possible in XDG_CONFIG, i.e. i don't want zimfw to go in HOME somewhere but rather it should come from .config/zsh or something. the config generated for nushell from HM should `use` (or import or whatever) a dir .config/nushell/user/ so that i can add custom configuration dynamically at runtime without reswitching HM.

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

tmux or zed

```
SYM     #(x$SHLVL) [ERR] GIT
```

GIT

```
[git_status]
up_to_date = "="
ahead = ">${count}"
behind = "<${count}"
diverged = "><${ahead_count}/${behind_count}"
untracked = "%${count}"
stashed = "$${count}"
conflicted = "!${count}"
modified = "*${count}"
staged = "+${count}"


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
- jujutsu
- tea
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
secrets/                  data, not a module — consumed only by features/home/secrets.nix
.zed/settings.json        project settings: direnv-loaded devshell env (nil from the devshell), nixfmt on save
modules/                  import-tree root; every .nix here is a flake-parts module
├── flake/                flake-specific config (flake outputs only)
│   ├── parts.nix         systems
│   ├── devshell.nix      devShells.default (lix-built nil + nixfmt), formatter
│   ├── lix.nix           flake.overlays.lix — binds the nix tool ecosystem to lixPackageSets.stable
│   └── standalone.nix    standalone homeConfigurations (bf@auto, bf@vm) — the class tree without an OS
├── system/
│   └── user.nix          user identity (flake.username) + the declared flake.homeModules option
├── features/
│   └── home/             the home-manager class tree, exported as flake.homeModules.*
│       ├── default.nix   aggregator: imports all classes, home.stateVersion lives here
│       ├── shell.nix     zsh (zimfw), nushell (`use user *`), zoxide, direnv
│       ├── tools.nix     rg fd bat eza bottom television uv + dust tlrc age sops lua deno
│       ├── git.nix       git delta jujutsu tea gh
│       ├── editor.nix    neovim (nvf), helix
│       ├── nix.nix       nh comma nom any-nix-shell, nix.settings, lix as nix.package
│       ├── gpg.nix       gpg identity (sops) + commit/tag signing
│       ├── ghostty.nix   ghostty (macOS: HM owns the config, the app comes from the cask)
│       ├── ssh.nix       ssh keys (public in-tree, private via sops)
│       └── secrets.nix   sops-nix HM module + age key location
└── hosts/                self-contained host files; they call nixosSystem/darwinSystem themselves
    ├── vm.nix            nixosConfigurations.vm + packages.vm (microvm runner)
    ├── devil.nix         nixosConfigurations.devil + packages.devil (rootfs tarball)
    └── auto.nix          darwinConfigurations.auto
```

## bootstrap

### macbook (`auto`)

```nu
# 1. lix owns the daemon — nix-darwin runs with nix.enable = false
curl -sSf -L https://install.lix.systems/lix | sh -s -- install

# 2. developer tools — git for the clone, toolchain for local builds
xcode-select --install

# 3. clone omni — nix-homebrew installs homebrew itself on first switch
git clone https://github.com/bfeitknecht/omni.git ~/.config/omni
cd ~/.config/omni

# 4. first switch (nh comes with the config itself)
sudo nix run nix-darwin#darwin-rebuild -- switch --flake .#auto

# 5. secrets — age key + encrypted store, then switch again
#    (full runbook: secrets/README.md)
age-keygen -y ~/.config/sops/age/keys.txt   # → .sops.yaml creation_rules
sops secrets/secrets.sops.yaml
nh darwin switch

# from here on, from anywhere:
nh darwin switch

# later, once the sops-managed key exists: switch the remote to ssh
```

### vm — the microvm test bed (on a NixOS host, e.g. the orbstack nixos vm)

```nu
git clone https://github.com/bfeitknecht/omni.git ~/.config/omni
cd ~/.config/omni
nix run .#vm                    # console autologin; TCG when /dev/kvm is missing
```

The guest shares the host /nix/store read-only with a writable tmpfs overlay,
so inside the vm: clone omni, `nh os switch .#vm`. Iterate on the host,
`nix run .#vm` again. QMP control socket: `/var/tmp/omni-vm.qmp`.

### devil — the kata pod image

```nu
# on a NixOS host — bootstrap only; day-to-day updates are `nh os switch`
# from inside the pod. --platform matters only if the build host is x86_64.
nix build .#devil
cp -L result/tarball/nixos-system-aarch64-linux.tar.xz .private/devil.tar.xz   # result points into the build host's nix store — dereference it
docker import --platform linux/arm64 .private/devil.tar.xz ghcr.io/bfeitknecht/devil:latest   # run where the docker daemon lives (OrbStack: on the mac)
docker push ghcr.io/bfeitknecht/devil:latest
```

The image is only the bootstrap (the entrypoint lives in the infra tree's
`applications/devil/deployment.yaml` as `command: ["/init"]`). Inside the
booted pod: clone omni, `nh os switch .#devil` — day-to-day
updates never touch the image. Access to devil.internal (LAN + tailnet only, the
router forwards nothing): **ssh** — port 2222, pubkey-only (`ssh/devil` in
sops; the private half rides to ish out-of-band); **ghostty-web** —
https://devil.internal, ttyd in the VM serves the infra-side static page
(ConfigMap) and puts a real `login` prompt on the pty — PAM validates bf's
password (`login/devil`, devil-only), the internal-allowlist middleware is
the only network gate; **teleport** — the agent stays in the image until the
teardown after the friend demo (ROADMAP), `tsh ssh bf@devil` keeps working
meanwhile. The join token arrives as a mounted Secret
(`/etc/teleport-secrets/teleport-token`).

## deferred

- starship prompt (spec above) — both shells, two TOML documents under
  `~/.config/starship/`
- podman (nixos only), openvpn/tailscale — undecided
