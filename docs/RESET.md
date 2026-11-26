# Reset runbook: echo -> anti

The next big step: factory-reset the MacBook Pro (`echo`) and bring it up as
`anti` from this flake. `docs/MIGRATION.md` is the inventory (what echo has);
this file is the order of work. Written 2026-11-25.

The owner has a backup of everything important in the user home. Time Machine
of the whole machine is optional (atlas `timemachine-mac`).

## A. The baseline (decided 2026-11-25: reset tonight)

The first switch is a minimal known-good state to return to. Rice comes
after, one piece at a time. What the baseline has:

- [x] **macOS settings:** function only (`modules/system/macos.nix`): Finder
      with Quit, screenshots to the clipboard, tap to click, no autocorrect,
      Touch ID for sudo. Dock, menu bar and look stay at Apple's defaults for
      now; echo's full set is in `MIGRATION.md` section 1.
- [x] **Casks:** the owner's list in `anti.nix` (`onActivation.cleanup = "zap"`
      removes anything not listed: install other apps through the list).
- [x] **Fonts:** CommitMono Nerd Font only.
- [x] **Zed:** vanilla, plus font, default theme
      (`features/home/editor.nix`).
- [x] **Colours:** shells (zsh highlighting and suggestions, nushell shapes and
      tables) and CLI tools use ANSI only; the frontend themes them
      (`features/home/theme.nix`).
- [x] **CLI tools:** carapace, lazygit, lazydocker, lazysql, yazi (bat previews),
      uutils coreutils, vivid; helix off.
- [x] **Wallpaper:** apex `brand/wallpaper.typ`, in `~/Pictures/Wallpapers`; `install.sh` sets it.
- Later, not in the baseline: App Store apps (`homebrew.masApps` needs the App
  Store login before the switch), Karabiner (copy `karabiner.json` from the
  backup for now), window manager, bar, launcher, login-screen tweaks.

## B. On echo, the last hour before the reset

1. **age key** `~/.config/sops/age/keys.txt` to two places off the Mac (Proton
   Pass and the home backup). It is the one key that cannot be recreated:
    - it decrypts omni `secrets/` (ssh keys github/forgejo/tangled/devil, gpg,
      model keys) and every infra `*.sops.yaml` (same recipient `age170rm…`);
    - infra `talos/talosconfig` and `kubeconfig` are gitignored, but they
      regenerate from `talos/secrets.sops.yaml` with this key
      (`topf talosconfig`, `topf kubeconfig`).
2. **Repos:** every repo pushed (`git status`, `git log @{u}..`). Gitignored
   state is only in the backup: `.private/` in infra, omni, apex, exhib;
   `exhib/uploads/`; infra `kubeconfig` and `talos/talosconfig` regenerate.
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

1. Setup assistant: Apple ID, **FileVault on**, Touch ID. The name does not
   matter: `install.sh` sets it to `anti`.
2. In Terminal.app, one command (have the age key from Proton Pass ready to
   paste; the script asks for it):

   ```sh
   curl -fsSL https://raw.githubusercontent.com/bfeitknecht/omni/master/install.sh | sh -s -- anti
   ```

   It installs the Xcode Command Line Tools, Lix, the age key, clones omni to
   `~/Projects/omni` (all repos live in `~/Projects/<name>`) and runs the
   first switch. sops-nix writes the ssh keys and the gpg identity.
3. Open Ghostty, log out and in once (Finder and trackpad apply then).
4. Tailscale: sign in, name `anti`; remove the old `echo` node in the admin
   console. Check `ssh bf@devil` and `kubectl` over the tailnet.
5. Clone the other repos from Forgejo to `~/Projects/<repo>`
   (`ssh://git@git.0xbf.ch/bf/<repo>.git`), then copy back the `.private/`
   dirs from the backup.
6. infra: `cd talos; topf talosconfig` and `topf kubeconfig | save -f ../kubeconfig`;
   check `kubectl get nodes`.
7. Internal CA: `install.sh` trusts `certs/internal-ca.crt`. Check that it is
   trusted: `security verify-cert -c ~/Projects/omni/certs/internal-ca.crt`.
8. atuin: the switch logs in from sops (`atuin/key`, `atuin/password`). Check
   with `atuin status`, then `atuin sync`.
9. CLI logins: `gh`, `tea`, `glab` (atlas `cli-logins`).
10. Manual rest (`MIGRATION.md` section 3): App Store login, Mail accounts,
    Swiss German input, login items, licences, Rex Beta + remote `devil`,
    Zed remote host `devil`.

## D. After

- Update infra atlas and ROADMAPs: echo is gone, anti is the daily driver.
- Delete the atlas items that named echo (`timemachine-mac`).
- Rice and the rest of `MIGRATION.md` one piece at a time, each behind
  `nh darwin switch`.
