# secrets

Encrypted per-user secrets (ssh keys, the gpg identity, tokens), consumed by
home-manager via sops-nix. Everything here is encrypted at rest with age;
encrypted files carry the `.sops.` pre-extension. Policy: one ed25519 ssh key
per service, no RSA.

The age key itself can never live inside sops — sops needs it to decrypt.
It lives at `~/.config/sops/age/keys.txt` on each machine; new machines
either generate a fresh key (then add its public half as a recipient below)
or receive the key file out-of-band.

## Bootstrap (once per machine)

```nu
# 1. age identity — never commit the private half
mkdir ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt

# 2. print the public key, add it to .sops.yaml (creation_rules.age,
#    comma-separated when several machines decrypt)
age-keygen -y ~/.config/sops/age/keys.txt
```

## Gotchas

- sops-nix **owns** the secret paths after activation (`~/.ssh/github`, …)
  and rewrites them on every switch — back up `~/.ssh` before the first
  secrets switch on a machine that already has keys, and make sure the
  sops file holds the exact current key material.
- nix reads **tracked** files only on a dirty tree: `git add` the sops file
  before switching.
- Rotating / adding recipients: `sops updatekeys secrets/secrets.sops.yaml`
