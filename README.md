# My dotfiles

Feel free to use whatever you want!

## Installer

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/ian-pascoe/dotfiles/master/install.sh | bash
```

```powershell
irm https://raw.githubusercontent.com/ian-pascoe/dotfiles/master/install.ps1 | iex
```

Run:

```bash
./install.sh
```

```powershell
./install.ps1
```

Useful flags:

- `--dry-run`: print planned actions without changing files
- `--strict`: fail on optional-step errors
- `--non-interactive`: skip steps that can block on prompts
- `--interactive`: force interactive behavior when auto-detection marks non-interactive
- `--install-yazi-pkgs`: run `ya pkg install` when yazi is present
