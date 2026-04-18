# Dotfiles (chezmoi)

i <3 config

Managed by chezmoi

## Bootstrap on a new machine

```bash
chezmoi init --apply git@github.com:zheller/dotfiles.git
```

`chezmoi init` uses `.chezmoi.toml.tmpl` to create/update your local config at `~/.config/chezmoi/chezmoi.toml`.

If you change `.chezmoi.toml.tmpl` later and want to refresh prompted values, run:

```bash
chezmoi update --init
```

## Unmanaged prerequisites

- Install Xcode Command Line Tools
- Configure SSH key for GitHub
- Install Homebrew
- Install `antidote` (or run `brew bundle` below, which installs it from Brewfile)
- Install Brewfile packages:

```bash
brew bundle install --file ~/Brewfile
```

## Notes

- Neovim plugins are managed by `lazy.nvim` via `~/.config/nvim`.
- Global 1Password env fallback is `~/.config/op/env`.
  - Project-local `./.env.op` or `./.env.1p` still takes precedence.
- Local/private chezmoi data lives in `~/.config/chezmoi/chezmoi.toml`.
  - Use it for PII and machine-local values like name, email, local paths, 1Password vault names, and additional/private Brewfile inventory.
  - The tracked `.chezmoi.toml.tmpl` bootstraps that file on `chezmoi init` / `chezmoi update --init`.
- The committed Brewfile includes the base CLI/dev toolchain required by these dotfiles.
  - Add machine-specific or personal packages via `[data.homebrew]` in local chezmoi config.
- Global pi config is managed under `~/.pi/agent/`.
  - `settings.json` loads the local `ai-toolbox` path from chezmoi config data.
  - `models.json` defines local/custom model providers.
