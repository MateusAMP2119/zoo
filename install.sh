#!/bin/sh
# installs zoo on macos and linux (wsl too), building from source when run from a checkout with cargo.
set -eu

REPO="${ZOO_REPO:-MateusAMP2119/zoo}"
BIN_DIR="$HOME/.local/bin"

say() { printf 'zoo: %s\n' "$*"; }
die() { printf 'zoo: %s\n' "$*" >&2; exit 1; }

# 1. claude code, through its official installer, which also uses ~/.local/bin.
if command -v claude >/dev/null 2>&1 || [ -x "$BIN_DIR/claude" ]; then
    say "claude code already installed"
else
    say "installing claude code"
    curl -fsSL https://claude.ai/install.sh | bash
fi

# 2. the zoo binary, built from this checkout or downloaded from the latest release.
mkdir -p "$BIN_DIR"
SRC_DIR=""
if [ -f "$0" ]; then SRC_DIR=$(cd "$(dirname "$0")" && pwd); fi
if [ -n "$SRC_DIR" ] && grep -qs '^name = "zoo"' "$SRC_DIR/Cargo.toml" && command -v cargo >/dev/null 2>&1; then
    say "building zoo from $SRC_DIR"
    cargo build --release --quiet --manifest-path "$SRC_DIR/Cargo.toml"
    cp "$SRC_DIR/target/release/zoo" "$BIN_DIR/zoo.tmp"
else
    case "$(uname -s)" in
        Darwin) os=apple-darwin ;;
        Linux) os=unknown-linux-musl ;;
        *) die "unsupported OS $(uname -s); on Windows use install.ps1" ;;
    esac
    case "$(uname -m)" in
        x86_64 | amd64) arch=x86_64 ;;
        arm64 | aarch64) arch=aarch64 ;;
        *) die "unsupported CPU $(uname -m)" ;;
    esac
    # rosetta reports x86_64 on apple silicon; the native build is the one to run.
    if [ "$os" = apple-darwin ] && [ "$(sysctl -n sysctl.proc_translated 2>/dev/null)" = 1 ]; then
        arch=aarch64
    fi
    url="https://github.com/$REPO/releases/latest/download/zoo-$arch-$os.tar.gz"
    say "downloading $url"
    tmp=$(mktemp -d)
    trap 'rm -rf "$tmp"' EXIT
    curl -fsSL "$url" -o "$tmp/zoo.tar.gz" || die "download failed"
    tar -xzf "$tmp/zoo.tar.gz" -C "$tmp"
    cp "$tmp/zoo" "$BIN_DIR/zoo.tmp"
fi
chmod +x "$BIN_DIR/zoo.tmp"
mv -f "$BIN_DIR/zoo.tmp" "$BIN_DIR/zoo"
say "installed $BIN_DIR/zoo"

# 3. ~/.local/bin on path, for shells opened from now on.
case ":$PATH:" in
    *":$BIN_DIR:"*) say "done, type: zoo" ;;
    *)
        case "$(basename "${SHELL:-sh}")" in
            zsh) rc="$HOME/.zshrc"; line='export PATH="$HOME/.local/bin:$PATH"' ;;
            # macos terminals start bash as a login shell, which reads .bash_profile.
            bash) rc="$HOME/.bashrc"; [ "$(uname -s)" = Darwin ] && rc="$HOME/.bash_profile"
                line='export PATH="$HOME/.local/bin:$PATH"' ;;
            fish) rc="$HOME/.config/fish/config.fish"; line='fish_add_path $HOME/.local/bin' ;;
            *) rc="$HOME/.profile"; line='export PATH="$HOME/.local/bin:$PATH"' ;;
        esac
        if ! grep -qs '\.local/bin' "$rc"; then
            mkdir -p "$(dirname "$rc")"
            printf '\n%s\n' "$line" >>"$rc"
            say "added ~/.local/bin to PATH in $rc"
        fi
        say "done, open a new terminal and type: zoo"
        ;;
esac
