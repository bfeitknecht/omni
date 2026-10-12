# secrets

Encrypted per-user secrets (ssh keys, gpg keys, tokens), consumed by
home-manager via sops-nix (`modules/home/secrets.nix`). Everything in here
is encrypted at rest with age. Every encrypted file must carry the `.sops.`
pre-extension: `<name>.sops.yaml`.

## Bootstrap (once)

```nu
# 1. generate the age key — never commit it
age-keygen -o ~/.config/sops/age/keys.txt

# 2. print the public key and put it into .sops.yaml (creation_rules.age)
age-keygen -y ~/.config/sops/age/keys.txt
```

## Create the first secrets file

```nu
# opens $EDITOR; sops encrypts on save using the .sops.yaml rules
sops secrets/secrets.sops.yaml
```

Then wire the entries in `modules/home/secrets.nix` (a commented example
is there: ssh key material via `sops.secrets`, public keys as plain
`home.file` entries since they are not secret).

## Rotating / adding recipients

```nu
# re-encrypt in place after changing .sops.yaml
sops updatekeys secrets/secrets.sops.yaml
```
