# agent-sandbox: run a coding agent on devil as bf, but without bf's power.
# bubblewrap (user namespace, no root) keeps the file system and the
# network, and takes away:
#   - root: bwrap sets no_new_privs, so sudo (setuid) cannot start;
#   - the secrets: the age key (it decrypts every infra and omni secret),
#     the ssh and gpg keys, the sops-nix files (the opencode model keys come
#     back read-only), the gpg agent and a forwarded ssh agent;
#   - the ways out of the sandbox: the systemd user manager and the D-Bus
#     session bus (systemd-run --user), the Rex server (its sessions run
#     outside), the Rex identity;
#   - persistence: shell, direnv, git, systemd user and Rex config are
#     read-only, so the agent cannot plant code that a later shell runs.
# /tmp is private. A soft boundary against prompt injection and mistakes;
# the hard one is the Kata VM around devil.
{
  writeShellApplication,
  bubblewrap,
  coreutils,
}:
writeShellApplication {
  name = "agent-sandbox";
  runtimeInputs = [
    bubblewrap
    coreutils
  ];
  text = ''
    # already inside (opencode starts `claude` from PATH): run it as it is
    if [ -n "''${AGENT_SANDBOX:-}" ]; then
      exec "$@"
    fi

    run="/run/user/$(id -u)"
    args=(
      --dev-bind / /
      --tmpfs /tmp
      --setenv AGENT_SANDBOX 1
      --unsetenv SSH_AUTH_SOCK
      --unsetenv DBUS_SESSION_BUS_ADDRESS
    )
    # a directory becomes an empty tmpfs, a file or socket becomes /dev/null
    hide() {
      local p
      for p in "$@"; do
        # a symlink (Home Manager): hide its target
        p="$(readlink -f "$p" || echo "$p")"
        if [ -d "$p" ]; then
          args+=(--tmpfs "$p")
        elif [ -e "$p" ]; then
          args+=(--ro-bind /dev/null "$p")
        fi
      done
    }
    # read-only; a symlink points into /nix/store and is read-only already
    readonly_() {
      local p
      for p in "$@"; do
        if [ -e "$p" ] && [ ! -L "$p" ]; then
          args+=(--ro-bind "$p" "$p")
        fi
      done
    }

    # the opencode model keys, resolved before secrets.d is hidden
    keys="$(readlink -f "$HOME/.config/sops-nix/secrets" || true)/opencode"

    hide \
      "$HOME/.ssh" "$HOME/.gnupg" "$HOME/.config/sops" "$HOME/.local/state/rex" \
      /run/secrets.d /run/secrets-for-users.d \
      "$run/secrets.d" "$run/gnupg" "$run/bus" "$run/systemd" "$run/rex"
    if [ -d "$keys" ]; then
      args+=(--ro-bind "$keys" "$keys")
    fi
    readonly_ \
      "$HOME/.zshenv" "$HOME/.config/zsh" "$HOME/.config/nushell" \
      "$HOME/.config/direnv" "$HOME/.local/share/direnv" \
      "$HOME/.config/git" "$HOME/.config/systemd" "$HOME/.config/rex"

    exec bwrap "''${args[@]}" -- "$@"
  '';
}
