# zoo

A wrapper around [Claude Code](https://claude.com/claude-code). Type `zoo` to launch it.

## Install

macOS / Linux / WSL:

```sh
curl -fsSL https://raw.githubusercontent.com/MateusAMP2119/zoo/main/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/MateusAMP2119/zoo/main/install.ps1 | iex
```

The installer installs Claude Code if it is missing, puts `zoo` in `~/.local/bin`
(next to `claude`), and adds that directory to your PATH if needed. Run it again to update.

From a checkout with Rust installed, `./install.sh` (or `.\install.ps1`) builds zoo from source instead.

## Use

```sh
zoo            # claude code
zoo <agent>    # claude code as the named agent (claude --agent <agent>)
```

## Uninstall

```sh
rm ~/.local/bin/zoo
```

## Release

Push a tag (`git tag v0.1.0 && git push --tags`); `.github/workflows/release.yml` builds
zoo for macOS, Linux and Windows (x86_64 and arm64) and publishes the archives the installers download.
