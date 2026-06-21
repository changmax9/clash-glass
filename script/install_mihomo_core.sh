#!/usr/bin/env bash
set -euo pipefail

VERSION="${MIHOMO_VERSION:-v1.19.27}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CORE_DIR="$ROOT_DIR/core"
CORE_PATH="$CORE_DIR/mihomo"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

case "$(uname -m)" in
  arm64)
    ASSET="mihomo-darwin-arm64-${VERSION}.gz"
    ;;
  x86_64)
    ASSET="mihomo-darwin-amd64-compatible-${VERSION}.gz"
    ;;
  *)
    echo "Unsupported macOS architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

URL="https://github.com/MetaCubeX/mihomo/releases/download/${VERSION}/${ASSET}"

mkdir -p "$CORE_DIR"
echo "Downloading Mihomo $VERSION"
curl -fL "$URL" -o "$TMP_DIR/mihomo.gz"
gzip -dc "$TMP_DIR/mihomo.gz" > "$CORE_PATH"
chmod +x "$CORE_PATH"
"$CORE_PATH" -v
