#!/bin/sh
# omni installer: a factory-fresh Mac to a configured host in one command.
#
#   curl -fsSL https://raw.githubusercontent.com/bfeitknecht/omni/master/install.sh | sh -s -- anti
#
# Steps (each is skipped when it is already done, so a re-run is safe):
#   1. checks: macOS on Apple silicon, not root, a known host, network
#   2. Xcode Command Line Tools (git, compilers; Homebrew needs them)
#   3. Lix, the nix implementation omni uses (its own installer, verbatim)
#   4. the age key (~/.config/sops/age/keys.txt), for omni's secrets
#   5. clone omni to ~/Projects/omni
#   6. the first switch: nix-darwin, home-manager, Homebrew and the casks
#
# Options: --dry-run (print the commands, change nothing), --yes (no
# confirmation prompt), --help. Env: OMNI_REPO (clone URL), OMNI_DIR (path).
#
# Everything is in main(), called on the last line: a download cut short
# runs nothing.

set -eu

OMNI_REPO="${OMNI_REPO:-https://github.com/bfeitknecht/omni.git}"
OMNI_DIR="${OMNI_DIR:-$HOME/Projects/omni}"
LIX_URL="https://install.lix.systems/lix"
AGE_KEY="$HOME/.config/sops/age/keys.txt"
TMP="${TMPDIR:-/tmp}"
TMP="${TMP%/}"
NIX_BIN=/nix/var/nix/profiles/default/bin
# darwin hosts in modules/hosts/; NixOS hosts (devil, vm) are not installed
# with this script
DARWIN_HOSTS="anti"

DRY_RUN=0
ASSUME_YES=0
HOST=""

# ---- output ---------------------------------------------------------------

if [ -t 1 ]; then
  BOLD="$(printf '\033[1m')"; DIM="$(printf '\033[2m')"; RED="$(printf '\033[31m')"
  GREEN="$(printf '\033[32m')"; YELLOW="$(printf '\033[33m')"; BLUE="$(printf '\033[34m')"
  RESET="$(printf '\033[0m')"
else
  BOLD=""; DIM=""; RED=""; GREEN=""; YELLOW=""; BLUE=""; RESET=""
fi

STEP=0
STEPS=6
step() { STEP=$((STEP + 1)); printf '\n%s==> [%s/%s] %s%s\n' "$BOLD$BLUE" "$STEP" "$STEPS" "$1" "$RESET"; }
info() { printf '    %s\n' "$*"; }
ok() { printf '    %s✓%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '    %s!%s %s\n' "$YELLOW" "$RESET" "$*"; }
die() { printf '\n%serror:%s %s\n' "$BOLD$RED" "$RESET" "$*" >&2; exit 1; }

# Print a command, then run it (or only print it with --dry-run). Its own
# output goes straight to the terminal.
run() {
  printf '    %s$ %s%s\n' "$DIM" "$*" "$RESET"
  [ "$DRY_RUN" -eq 1 ] && return 0
  "$@"
}

# Prompts read from the terminal: with `curl | sh`, stdin is the script.
ask() {
  [ "$ASSUME_YES" -eq 1 ] && return 0
  printf '    %s [y/N] ' "$1"
  read -r answer </dev/tty || die "no terminal to ask on; re-run with --yes"
  case "$answer" in y | Y | yes | YES) return 0 ;; *) return 1 ;; esac
}

usage() {
  cat <<EOF
omni installer

  curl -fsSL https://raw.githubusercontent.com/bfeitknecht/omni/master/install.sh | sh -s -- <host> [options]
  sh install.sh <host> [options]

Hosts: $DARWIN_HOSTS
Options:
  --dry-run   print every command, change nothing
  --yes       do not ask before starting
  --help      this text
EOF
}

# ---- steps ----------------------------------------------------------------

checks() {
  step "Checks"
  [ "$(uname -s)" = "Darwin" ] || die "this installer is for macOS (uname -s: $(uname -s)). NixOS hosts: see README."
  [ "$(uname -m)" = "arm64" ] || die "omni's darwin hosts are aarch64-darwin (uname -m: $(uname -m))."
  ok "macOS $(sw_vers -productVersion) on Apple silicon ($(sysctl -n hw.model 2>/dev/null || echo unknown model))"

  [ "$(id -u)" -ne 0 ] || die "do not run as root or with sudo: the installer asks for sudo itself where it needs it."
  ok "running as $(id -un); sudo is asked for when needed (Lix, the first switch, Homebrew)"

  case " $DARWIN_HOSTS " in
    *" $HOST "*) ok "host: $HOST" ;;
    *) die "unknown host '$HOST'. Darwin hosts: $DARWIN_HOSTS" ;;
  esac

  curl -fsS -o /dev/null --max-time 10 https://github.com ||
    die "no connection to github.com: connect to the network first."
  ok "network: github.com reachable"

  if [ -x /usr/bin/fdesetup ] && /usr/bin/fdesetup status 2>/dev/null | grep -q "FileVault is On"; then
    ok "FileVault is on"
  else
    warn "FileVault is off. Turn it on: System Settings > Privacy & Security > FileVault (not declarable in nix)."
  fi
}

manual_notice() {
  printf '\n%sBefore and after: steps only you can do%s\n' "$BOLD" "$RESET"
  cat <<EOF
    Before (setup assistant, already done if you are reading this):
      - Apple ID / iCloud sign-in, Touch ID
      - FileVault on (System Settings > Privacy & Security)
      - the Mac's name does not matter: the switch sets it to '$HOST'
    During this script:
      - your password for sudo (Lix, the first switch, Homebrew casks)
      - the Xcode Command Line Tools dialog: click Install
      - the age key: paste it when asked (Proton Pass), or put it at
        $AGE_KEY before you start
    After:
      - log out and in once (Dock, Finder, trackpad settings apply then)
      - \`wallpaper\` (allow the terminal to control System Events)
      - Tailscale app: sign in; App Store sign-in for store apps
      - docs/RESET.md section C has the rest (repos, kubeconfig, CA, CLI logins)
EOF
}

xcode_tools() {
  step "Xcode Command Line Tools"
  if xcode-select -p >/dev/null 2>&1; then
    ok "installed at $(xcode-select -p)"
    return 0
  fi
  info "Not installed. macOS opens a dialog: click Install and accept the licence."
  info "This script waits until the install is done (a few minutes)."
  run xcode-select --install || true
  [ "$DRY_RUN" -eq 1 ] && return 0
  while ! xcode-select -p >/dev/null 2>&1; do
    sleep 10
    printf '.'
  done
  printf '\n'
  ok "installed at $(xcode-select -p)"
}

lix() {
  step "Lix (nix)"
  if [ -x "$NIX_BIN/nix" ]; then
    ok "already installed: $("$NIX_BIN/nix" --version | head -n 1)"
  else
    info "The Lix installer runs now with its own output and questions."
    info "It creates the /nix volume and the nix daemon, and asks for sudo."
    info "Source: $LIX_URL"
    # Downloaded first, then run with the terminal as stdin: its questions
    # need the keyboard, and this script's stdin is the `curl | sh` pipe.
    lix_installer="$TMP/lix-installer.sh"
    run curl -sSf -L -o "$lix_installer" "$LIX_URL"
    if [ "$DRY_RUN" -eq 1 ]; then
      run sh "$lix_installer" install
    else
      printf '    %s$ sh %s install%s\n' "$DIM" "$lix_installer" "$RESET"
      sh "$lix_installer" install </dev/tty
    fi
    run rm -f "$lix_installer"
  fi
  # this shell does not have nix on PATH yet
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck disable=SC1091
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  fi
  # flakes for this script's nix calls, whatever nix.conf says
  export NIX_CONFIG="extra-experimental-features = nix-command flakes"
  [ "$DRY_RUN" -eq 1 ] || command -v nix >/dev/null || die "nix is not on PATH after the Lix install."
  [ "$DRY_RUN" -eq 1 ] || ok "$(nix --version | head -n 1)"
}

age_key() {
  step "age key (secrets)"
  if [ -s "$AGE_KEY" ]; then
    ok "found: $AGE_KEY"
    return 0
  fi
  info "omni's secrets (ssh keys, gpg, model keys) are encrypted to this key."
  info "Without it the switch still runs, but no secret is written."
  if ask "Paste the age key now (input hidden)?"; then
    [ "$DRY_RUN" -eq 1 ] && { info "(dry run: nothing read)"; return 0; }
    mkdir -p "$(dirname "$AGE_KEY")"
    chmod 700 "$(dirname "$AGE_KEY")"
    info "Paste the whole key file (the AGE-SECRET-KEY-1... line is enough), then Enter:"
    stty -echo </dev/tty
    read -r key </dev/tty || true
    stty echo </dev/tty
    case "$key" in
      AGE-SECRET-KEY-1*) ;;
      *) die "that is not an age secret key (expected AGE-SECRET-KEY-1...)." ;;
    esac
    (umask 077 && printf '%s\n' "$key" >"$AGE_KEY")
    key=""
    ok "written: $AGE_KEY (mode 600)"
  else
    warn "continuing without the age key. Later: put it at $AGE_KEY, then \`nh darwin switch\`."
  fi
}

clone() {
  step "omni repository"
  if [ -d "$OMNI_DIR/.git" ]; then
    ok "already cloned: $OMNI_DIR"
    run git -C "$OMNI_DIR" pull --ff-only
  else
    run mkdir -p "$(dirname "$OMNI_DIR")"
    run git clone "$OMNI_REPO" "$OMNI_DIR"
  fi
  # the host must exist in the flake, not only in this script's list
  if [ "$DRY_RUN" -eq 0 ]; then
    hosts="$(nix eval --raw "$OMNI_DIR#darwinConfigurations" --apply 'c: builtins.concatStringsSep " " (builtins.attrNames c)')"
    case " $hosts " in
      *" $HOST "*) ok "flake has darwinConfigurations.$HOST" ;;
      *) die "the flake has no darwinConfigurations.$HOST (has: $hosts)" ;;
    esac
  fi
}

first_switch() {
  step "First switch: nix-darwin, home-manager, Homebrew"
  info "Builds the whole system (several GB on a fresh machine), then activates it."
  info "Homebrew is installed by nix-homebrew, the casks after it; this takes a while."
  # The Lix installer edits these shell files; nix-darwin refuses to replace
  # files it did not write. Keep them as .before-nix-darwin, as it suggests.
  for f in /etc/bashrc /etc/zshrc /etc/zshenv; do
    if [ -f "$f" ] && [ ! -L "$f" ]; then
      run sudo mv "$f" "$f.before-nix-darwin"
    fi
  done
  # Build as the user first (output below), then activate with the
  # darwin-rebuild of that build: the nix-darwin version omni's flake.lock
  # pins. sudo resets PATH: give it nix and the system dirs.
  system="$TMP/omni-$HOST-system"
  run nix build --print-out-paths -o "$system" "$OMNI_DIR#darwinConfigurations.$HOST.system"
  run sudo -H env PATH="$NIX_BIN:/usr/bin:/bin:/usr/sbin:/sbin" NIX_CONFIG="$NIX_CONFIG" "$system/sw/bin/darwin-rebuild" switch --flake "$OMNI_DIR#$HOST"
  run rm -f "$system"
}

done_notice() {
  printf '\n%s%s==> %s is set up.%s\n' "$BOLD" "$GREEN" "$HOST" "$RESET"
  cat <<EOF

    From now on, from anywhere:   nh darwin switch
    The repository:               $OMNI_DIR

    Now:
      1. Open a new terminal (Ghostty), so the new shell and PATH load.
      2. Log out and in once.
      3. \`wallpaper\`
      4. Tailscale: sign in in the app (name: $HOST).
      5. The rest: $OMNI_DIR/docs/RESET.md section C.
EOF
}

main() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --yes) ASSUME_YES=1 ;;
      -h | --help) usage; exit 0 ;;
      -*) usage; die "unknown option $1" ;;
      *) [ -z "$HOST" ] || die "one host only"; HOST="$1" ;;
    esac
    shift
  done
  [ -n "$HOST" ] || { usage; die "name the host, e.g. sh -s -- anti"; }

  printf '%somni installer%s: this Mac becomes %s%s%s\n' "$BOLD" "$RESET" "$BOLD" "$HOST" "$RESET"
  printf '%s%s%s\n' "$DIM" "$OMNI_REPO -> $OMNI_DIR" "$RESET"
  [ "$DRY_RUN" -eq 1 ] && printf '%sdry run: commands are printed, not run%s\n' "$YELLOW" "$RESET"

  checks
  manual_notice
  printf '\n'
  ask "Start? This installs Lix and Homebrew and changes system settings." || die "stopped, nothing changed."

  xcode_tools
  lix
  age_key
  clone
  first_switch
  done_notice
}

main "$@"
