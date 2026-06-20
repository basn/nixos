{ pkgs, ... }:
let
  cachyosProtonV3 = pkgs.writeShellScriptBin "cachyos-proton-v3" ''
    set -euo pipefail

    usage() {
      echo "Usage: cachyos-proton-v3 [compatibilitytools.d]" >&2
      exit 1
    }

    if [ "$#" -gt 1 ]; then
      usage
    fi

    steam_root="$HOME/.steam/root"
    if [ ! -d "$steam_root" ] && [ -d "$HOME/.local/share/Steam" ]; then
      steam_root="$HOME/.local/share/Steam"
    fi

    install_root="''${1:-''${STEAM_COMPAT_TOOLS_DIR:-$steam_root/compatibilitytools.d}}"
    api_url="https://api.github.com/repos/CachyOS/proton-cachyos/releases/latest"

    release_json="$(${pkgs.curl}/bin/curl -fsSL "$api_url")"
    tag="$(${pkgs.jq}/bin/jq -r '.tag_name' <<< "$release_json")"
    archive_name="$(
      ${pkgs.jq}/bin/jq -r '
        .assets[]
        | select(.name | test("x86_64_v3\\.tar\\.xz$"))
        | .name
      ' <<< "$release_json" | head -n 1
    )"
    archive_url="$(
      ${pkgs.jq}/bin/jq -r --arg name "$archive_name" '
        .assets[]
        | select(.name == $name)
        | .browser_download_url
      ' <<< "$release_json"
    )"
    checksum_name="$(
      ${pkgs.jq}/bin/jq -r '
        .assets[]
        | select(.name | test("x86_64_v3\\.sha512sum$"))
        | .name
      ' <<< "$release_json" | head -n 1
    )"
    checksum_url="$(
      ${pkgs.jq}/bin/jq -r --arg name "$checksum_name" '
        .assets[]
        | select(.name == $name)
        | .browser_download_url
      ' <<< "$release_json"
    )"

    if [ -z "$archive_name" ] || [ "$archive_name" = "null" ]; then
      echo "No CachyOS Proton x86_64_v3 archive found in latest release: $tag" >&2
      exit 1
    fi
    if [ -z "$checksum_name" ] || [ "$checksum_name" = "null" ]; then
      echo "No CachyOS Proton x86_64_v3 checksum found in latest release: $tag" >&2
      exit 1
    fi

    expected_dir="''${archive_name%.tar.xz}"
    if [ -d "$install_root/$expected_dir" ]; then
      echo "$expected_dir is already installed in $install_root"
      exit 0
    fi

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    echo "Downloading $archive_name from $tag"
    ${pkgs.curl}/bin/curl -fL "$archive_url" -o "$tmpdir/$archive_name"
    ${pkgs.curl}/bin/curl -fL "$checksum_url" -o "$tmpdir/$checksum_name"

    (
      cd "$tmpdir"
      ${pkgs.coreutils}/bin/sha512sum -c "$checksum_name"
    )

    ${pkgs.gnutar}/bin/tar -tf "$tmpdir/$archive_name" > "$tmpdir/archive-files"
    top_dir="$(${pkgs.gawk}/bin/awk -F/ 'NF { print $1; exit }' "$tmpdir/archive-files")"
    if [ -z "$top_dir" ]; then
      echo "Could not determine archive top-level directory" >&2
      exit 1
    fi
    if [ -d "$install_root/$top_dir" ]; then
      echo "$top_dir is already installed in $install_root"
      exit 0
    fi

    mkdir -p "$install_root"
    ${pkgs.gnutar}/bin/tar -xf "$tmpdir/$archive_name" -C "$install_root"
    echo "Installed $top_dir to $install_root"
    echo "Restart Steam to make the compatibility tool visible."
  '';
in
{
  environment.systemPackages = [ cachyosProtonV3 ];
}
