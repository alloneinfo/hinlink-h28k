#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./config.sh
source "$SCRIPT_DIR/config.sh"

resolve_official_kmods() {
  local version="$1" kmods
  kmods="$(curl -fsSL \
    "https://downloads.immortalwrt.org/releases/$version/targets/rockchip/armv8/kmods/" \
    | sed -nE 's#.*href="([^"]*-[0-9a-f]{32})/".*#\1#p' \
    | head -n 1)"
  [[ "$kmods" =~ -[0-9a-f]{32}$ ]] || return 1
  printf '%s\n' "$kmods"
}

config_file="${1:-}"
github_output="${2:-}"
[[ -n "$config_file" && -n "$github_output" ]] ||
  fail "usage: $0 <firmware.conf> <github-output>"
upstream=https://github.com/immortalwrt/immortalwrt.git
load_firmware_config "$config_file"
requested_version="${release_version#v}"
[[ -n "$requested_version" ]] || fail "release_version must be 24.10, 25.12, or an exact supported version"

release_tag=""
if [[ "$requested_version" =~ ^(24\.10|25\.12)$ ]]; then
  release_series="$requested_version"
elif [[ "$requested_version" =~ ^(24\.10|25\.12)\.[0-9]+$ ]]; then
  release_version="$requested_version"
  release_series="${release_version%.*}"
  release_tag="v$release_version"
  git ls-remote --exit-code --tags --refs "$upstream" "refs/tags/$release_tag" >/dev/null ||
    fail "upstream release tag not found: $release_tag"
  kernel_kmods="$(resolve_official_kmods "$release_version")" ||
    fail "official kmods not found for $release_version"
else
  fail "unsupported release version or series: $release_version"
fi

if [[ -z "$release_tag" ]]; then
  release_prefix="v${release_series}."
  for tag in $(git ls-remote --tags --refs "$upstream" 'refs/tags/v*' \
    | awk -F/ -v prefix="$release_prefix" \
      '$3 ~ /^v[0-9]+\.[0-9]+\.[0-9]+$/ && index($3, prefix) == 1 { print $3 }' \
    | sort -Vr); do
    version="${tag#v}"
    if kernel_kmods="$(resolve_official_kmods "$version")"; then
      release_tag="$tag"
      release_version="$version"
      break
    fi
  done
  [[ -n "$release_tag" ]] || fail "no usable $release_series release was found"
fi
{
  echo "series=$release_series"
  echo "tag=$release_tag"
  echo "version=$release_version"
  echo "kernel_kmods=$kernel_kmods"
} >> "$github_output"

echo "Selected ImmortalWrt release: $release_tag"
