# Migration: echo -> anti

What moves from the old MacBook Pro (`echo`, Mac14,9, macOS 27.0.1) to the new
one (`anti`). Read from echo on 2026-11-19 (`defaults read`, `brew`, `mas`,
`/Applications`, `~/.config`). Nothing here is applied: `anti` is the old `auto`
config. Pick what you want from each section.

## 1. macOS settings on echo (pick what you want)

None of this is in `anti.nix`. `anti` is the old `auto` config only.
The table is what echo has; the block below is ready to paste into
`anti.nix` (inside the module, next to `homebrew`). Delete the lines you
don't want.

| Area          | Setting                                                                                                                                                                 |
| ------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Dock          | autohide, no delay, 0.15 s animation, left, size 42, no magnification, genie, no recent apps                                                                            |
| Hot corners   | top right Quick Note (14), bottom right app windows (3)                                                                                                                 |
| Finder        | Quit menu item, path bar, no status bar, list view, search current folder, no extension warning, new window = Home, drives and servers on desktop                       |
| Stage Manager | off; click on wallpaper does not show the desktop; no tiling margins, no top-edge tiling                                                                                |
| Screenshots   | to clipboard, no shadow, date in name, no thumbnail, `~/Pictures/Screenshots`                                                                                           |
| Trackpad      | tap to click, two-finger right click, no three-finger drag, light click                                                                                                 |
| Clock         | date, weekday, seconds, AM/PM                                                                                                                                           |
| Text          | no auto-capitalization, no autocorrect, no period shortcut, no inline prediction                                                                                        |
| Windows       | dark mode, tabs always, window animations off, all extensions shown, double-click title = nothing                                                                       |
| Glass         | `NSGlassDiffusionSetting = 1`, desktop tinting off, blurred menu bar. **Check after the first switch**: the key is right, the value is not verified against the slider. |
| Menu bar      | `AutoHideMenuBarOption = 3`, visible in full screen                                                                                                                     |

```nix
system.defaults = {
  dock = {
    autohide = true;
    autohide-delay = 0.0;
    autohide-time-modifier = 0.15;
    orientation = "left";
    tilesize = 42;
    magnification = false;
    mineffect = "genie";
    minimize-to-application = false;
    show-recents = false;
    show-process-indicators = true;
    # hot corners: top right Quick Note, bottom right app windows
    wvous-tr-corner = 14;
    wvous-br-corner = 3;
  };

  finder = {
    QuitMenuItem = true;
    ShowPathbar = true;
    ShowStatusBar = false;
    FXPreferredViewStyle = "Nlsv"; # list view
    FXDefaultSearchScope = "SCcf"; # search the current folder
    FXEnableExtensionChangeWarning = false;
    NewWindowTarget = "Home";
    ShowExternalHardDrivesOnDesktop = true;
    ShowHardDrivesOnDesktop = false;
    ShowRemovableMediaOnDesktop = true;
    ShowMountedServersOnDesktop = true;
  };

  WindowManager = {
    GloballyEnabled = false; # Stage Manager off
    AutoHide = true;
    HideDesktop = true;
    EnableTiledWindowMargins = false;
    EnableTopTilingByEdgeDrag = false;
    StageManagerHideWidgets = false;
    StandardHideWidgets = false;
  };

  screencapture = {
    target = "clipboard";
    disable-shadow = true;
    include-date = true;
    show-thumbnail = false;
    location = "~/Pictures/Screenshots";
  };

  trackpad = {
    Clicking = true; # tap to click
    TrackpadRightClick = true;
    TrackpadThreeFingerDrag = false;
    Dragging = false;
    ActuateDetents = true;
    FirstClickThreshold = 1;
    SecondClickThreshold = 1;
  };

  menuExtraClock = {
    ShowAMPM = true;
    ShowDate = 1;
    ShowDayOfWeek = true;
    ShowSeconds = true;
    IsAnalog = false;
  };

  NSGlobalDomain = {
    AppleInterfaceStyle = "Dark";
    AppleShowAllExtensions = true;
    AppleKeyboardUIMode = 0;
    AppleWindowTabbingMode = "always";
    AppleSpacesSwitchOnActivate = true;
    AppleEnableSwipeNavigateWithScrolls = true;
    NSAutomaticCapitalizationEnabled = false;
    NSAutomaticSpellingCorrectionEnabled = false;
    NSAutomaticPeriodSubstitutionEnabled = false;
    NSAutomaticInlinePredictionEnabled = false;
    NSAutomaticWindowAnimationsEnabled = false;
    NSTableViewDefaultSizeMode = 2;
    _HIHideMenuBar = false;
    "com.apple.swipescrolldirection" = true;
    "com.apple.trackpad.scaling" = 1.0;
    "com.apple.sound.beep.feedback" = 1;
  };

  # keys nix-darwin has no typed option for
  CustomUserPreferences = {
    NSGlobalDomain = {
      AppleMenuBarVisibleInFullscreen = true;
      # Liquid Glass (macOS 26+): the Appearance slider
      NSGlassDiffusionSetting = 1;
      AppleReduceDesktopTinting = true;
      SLSMenuBarUseBlurredAppearance = true;
      NSCloseAlwaysConfirmsChanges = true;
      NSQuitAlwaysKeepsWindows = true;
      AppleActionOnDoubleClick = "None";
    };
    "com.apple.WindowManager".AppWindowGroupingBehavior = 1;
    "com.apple.controlcenter".AutoHideMenuBarOption = 3;
  };
};
```

Keys under `CustomUserPreferences` have no typed nix-darwin option. A typo
there fails silently; the typed ones fail the eval.

## 2. Easy to declare (not done yet)

### Homebrew casks (`homebrew.casks` in `anti.nix`)

`anti` has zed and ghostty active and a commented list. In use on echo:

anki, audacity, autodesk-fusion, balenaetcher, blender, bruno, claude-code,
discord, element, firefox, handy, iterm2, karabiner-elements, kathara,
keycastr, kiwix, obsidian, orbstack, prusaslicer, raspberry-pi-imager,
raycast, shapr3d, signal, spotify, stats, steam, tailscale-app, topf, utm,
whatsapp, zed-delta.

Apps on echo that are not casks: DaVinci Resolve and the Blackmagic tools, Cisco
Secure Client (ETH VPN), Code Expert Sync, Nord Sample Editor and Sound Manager,
STMicroelectronics tools, Zathura, Graphing Calc, Rex Beta (dmg, beta).

### App Store (`homebrew.masApps`)

```nix
homebrew.masApps = {
  Amphetamine = 937984704;
  "ETH Video" = 6458144304;
  "Sweet Home 3D" = 669289700;
};
```

Needs an App Store login before the first switch.

### Dock apps (`system.defaults.dock.persistent-apps`)

echo pins: System Settings, iTerm, Obsidian, Safari, Mail, WhatsApp, Spotify.

### Fonts (`fonts.packages` with `pkgs.nerd-fonts.*`)

echo has 186 font files in `~/Library/Fonts`, all Nerd Fonts: Aurulent Sans
Mono, Blex Mono, Commit Mono, Cousine, Fira Mono, Gohu, Hack, Inconsolata Go,
Meslo. Keep the ones you use (Commit Mono is the site font).

### Config files (`xdg.configFile` in a home module)

Files in `~/.config` on echo that no nix module writes. Bring the ones you
care about into omni:

- **karabiner** (`karabiner.json`): the key remaps.
- **zed** (`settings.json`, `keymap.json`, `tasks.json`, `themes/`): ROADMAP item.
- helix, lazygit, lazydocker, btop, gh, aichat, opencode, television, micro,
  mpv, iterm2, raycast (Raycast exports its own settings file).

### CLI tools (brew formulae -> `home.packages`)

The home modules already cover age, bat, bottom, direnv, eza, fd, gh, git,
helix, nushell, starship, television, uv, zoxide. Some others may come in
through `programs.*` (delta, jujutsu, neovim via nvf, gpg): check before
adding. Not found in omni:

aichat, ansible, bun, carapace, cloc, cmake, coreutils, deno, dust, dysk, elm,
fluxcd, fzf, gdb, ghcup, git-lfs, gleam, go, helm, hlint, hugo, just, k3d,
kotlin, kubectl, lazydocker, lazygit, lf, luarocks, macchina, ninja, nmap,
node, oci-cli, ollama, onefetch, opam, opencode, pinentry-mac, pkl,
presenterm, procs, protobuf, pwgen, python, qemu, rlwrap, rustup, sbcl,
slides, sops, sshpass, stow, talosctl, thefuck, tlrc, tmux, tokei, tor,
totp-cli, typos, typst, typstyle, tinymist, wabt, wasmtime, wget, yamlfmt,
yazi, z3, zig, zola.

Many of these belong in per-project dev shells (direnv), not in the global
home: compilers and language tools especially.

## 3. Manual (not declarable, or not worth it)

- **FileVault**: turn on during setup.
- **Apple ID, iCloud, App Store login**, Touch ID, Apple Pay.
- **Wallpaper**, notification settings, Focus modes, Control Center layout
  (stored as binary blobs).
- **Keyboard**: input source Swiss German, plus 49 system shortcuts in
  `com.apple.symbolichotkeys`. Set by hand; the plist is fragile.
- **Login items**: Cisco Secure Client, Umbra, OrbStack, Raycast,
  Amphetamine, noTunes, Stats. Most apps add themselves on first start.
- **Accounts and licences**: Mail accounts, DaVinci Resolve, Shapr3D,
  Autodesk Fusion, Steam, Discord, Element, Signal (link the device).
- **Browsers**: Firefox and Safari profiles, passwords live in Proton Pass.
- **Internal CA**: install the cluster's `.internal` CA in the System keychain
  and trust it (infra AGENTS.md, certificates).
- **Rex**: install Rex Beta from the dmg, then **Add Remote Host** ->
  `ssh://devil.internal`. omni writes `init.lua` already.

## 4. Data to carry (before the reset)

1. **age key** `~/.config/sops/age/keys.txt` first: every sops secret in omni
   and infra hangs off it.
2. Code under `~/HOME/CODE`: everything is in git; check for unpushed work and
   for `.private/` dirs (gitignored).
3. Obsidian vault, `~/Pictures/Screenshots`, Downloads you want to keep.
4. Time Machine to `smb://10.10.20.145` as the rollback.
