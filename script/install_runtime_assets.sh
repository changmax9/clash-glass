#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESTINATION="$ROOT_DIR/runtime-assets"
TMP_DIR="$(mktemp -d)"
BASE_URL="https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

download() {
  local asset="$1"
  local destination_name="$2"

  echo "Downloading $asset"
  curl -fL "$BASE_URL/$asset" -o "$TMP_DIR/$asset"
  curl -fL "$BASE_URL/$asset.sha256sum" -o "$TMP_DIR/$asset.sha256sum"
  (
    cd "$TMP_DIR"
    shasum -a 256 -c "$asset.sha256sum"
  )
  mv "$TMP_DIR/$asset" "$DESTINATION/$destination_name"
}

mkdir -p "$DESTINATION"
download "geoip.dat" "geoip.dat"
download "geoip.metadb" "geoip.metadb"
download "geosite.dat" "geosite.dat"
download "GeoLite2-ASN.mmdb" "ASN.mmdb"

echo "Mihomo Geo data installed in $DESTINATION"
