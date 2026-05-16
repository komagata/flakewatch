#!/bin/sh
set -eu

VERSION="${FLAKEWATCH_VERSION:-v0.5.0}"
INSTALL_DIR="${FLAKEWATCH_INSTALL_DIR:-/usr/local/bin}"
TMP_DIR="${TMPDIR:-/tmp}"

os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
  Linux) os_name="linux" ;;
  *)
    echo "unsupported OS: $os" >&2
    exit 1
    ;;
esac

case "$arch" in
  x86_64|amd64) arch_name="amd64" ;;
  *)
    echo "unsupported architecture: $arch" >&2
    exit 1
    ;;
esac

asset="flakewatch-${VERSION}-${os_name}-${arch_name}.tar.gz"
url="https://github.com/komagata/flakewatch/releases/download/${VERSION}/${asset}"
archive="${TMP_DIR}/${asset}"

curl -fsSL -o "$archive" "$url"
tar -xzf "$archive" -C "$TMP_DIR"

if [ -w "$INSTALL_DIR" ]; then
  install "$TMP_DIR/flakewatch" "$INSTALL_DIR/flakewatch"
else
  sudo install "$TMP_DIR/flakewatch" "$INSTALL_DIR/flakewatch"
fi

"$INSTALL_DIR/flakewatch" doctor
