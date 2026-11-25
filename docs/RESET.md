# Reset runbook: echo -> anti

The next big step: factory-reset the MacBook Pro (`echo`) and bring it up as
`anti` from this flake. `docs/MIGRATION.md` is the inventory (what echo has);
this file is the order of work. Written 2026-11-25.

The owner has a backup of everything important in the user home. Time Machine
of the whole machine is optional (atlas `timemachine-mac`).

## A. Decide before the day (agent prepares, owner picks)

Each item ends in a commit on omni master. Nothing here is urgent alone, but
whatever is not in `anti.nix` on the day is manual work after the reset.

- [ ] **macOS defaults:** take the block in `MIGRATION.md` section 1 as a whole,
      or strike lines. The agent pastes it into `anti.nix` and checks the eval.
- [ ] **Casks:** which of the list in `MIGRATION.md` section 2 go into
      `homebrew.casks` (`onActivation.cleanup = "zap"` removes anything not listed).
- [ ] **App Store apps** (`homebrew.masApps`): Amphetamine, ETH Video, Sweet Home 3D?
- [ ] **Fonts:** which Nerd Fonts (Commit Mono at least).
- [ ] **Zed settings into nix** now, or copy `~/.config/zed` from the backup and
      move it later.
- [ ] **Karabiner** `karabiner.json` into omni, or copy from the backup.
- [ ] **CLI tools:** global (`home.packages`) or per-project dev shells. Only
      the ones you need on day one matter.

## B. On echo, the last hour before the reset

1. **age key** `~/.config/sops/age/keys.txt` to two places off the Mac (Proton
   Pass and the home backup). It is the one key that cannot be recreated:
   - it decrypts omni `secrets/` (ssh keys github/forgejo/tangled/devil, gpg,
     model keys) and every infra `*.sops.yaml` (same recipient `age170rm…`);
   - infra `talos/talosconfig` and `kubeconfig` are gitignored, but they
     regenerate from `talos/secrets.sops.yaml` with this key
     (`topf talosconfig`, `topf kubeconfig`).
2. **Repos:** every repo pushed (`git status`, `git log @{u}..`). The GENESIS
   repos are clean as of 2026-11-25. Gitignored state is only in the backup:
   `.private/` in infra, omni, apex, exhib; `exhib/uploads/`.
3. **ssh keys not in sops:** `id_ed25519`, `id_ed25519_nico`, `id_rsa`,
   `oci_console_rsa`, `soseth.config`. Check they are in the backup, or drop
   the ones you no longer use.
4. **atuin key:** `atuin key` and save the words in Proton Pass. Without it the
   synced history on `atuin.0xbf.ch` cannot be read on the new machine.
5. **Claude Code memory:** `~/.claude/` (project memories) is in the backup.
6. **Rex:** note the remote hosts (`~/Library/Application Support/Rex/servers`).
7. **Apple:** sign out of iCloud (Find My off), deauthorise Music/TV if used.
8. Erase: System Settings > General > Transfer or Reset > Erase All Content
   and Settings.

## C. Day one on anti

Follow the README bootstrap. Order and checks:

1. Setup assistant: name the Mac `anti`, Apple ID, **FileVault on**, Touch ID.
2. `xcode-select --install`, then the lix installer.
3. age key back to `~/.config/sops/age/keys.txt` (mode 600).
4. Clone omni (`~/HOME/CODE/GENESIS/omni`, the path echo used) and switch:
   `sudo nix run nix-darwin#darwin-rebuild -- switch --flake .#anti`, after
   that `nh darwin switch`. sops-nix writes the ssh keys and the gpg identity.
5. Tailscale: sign in, name `anti`; remove the old `echo` node in the admin
   console. Check `ssh bf@devil` and `kubectl` over the tailnet.
6. Clone the other repos from Forgejo (`ssh://git@git.0xbf.ch/bf/<repo>.git`),
   then copy back the `.private/` dirs from the backup.
7. infra: `cd talos; topf talosconfig` and `topf kubeconfig | save -f ../kubeconfig`;
   check `kubectl get nodes`.
8. Internal CA into the System keychain and trust it (infra AGENTS, Internal CA).
9. atuin: `atuin login` with the saved key, `atuin sync`.
10. CLI logins: `gh`, `tea`, `glab` (atlas `cli-logins`).
11. Manual rest (`MIGRATION.md` section 3): App Store login, Mail accounts,
    Swiss German input, login items, licences, Rex Beta + remote `devil`,
    Zed remote host `devil`.

## D. After

- Update infra atlas and ROADMAPs: echo is gone, anti is the daily driver.
- Delete the atlas items that named echo (`timemachine-mac`).
- Rice and the rest of `MIGRATION.md` one piece at a time, each behind
  `nh darwin switch`.
