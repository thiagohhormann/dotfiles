#!/usr/bin/env bash
set -euo pipefail

repo="obsidianmd/obsidian-releases"

app_name="obsidian"
app_dir="$HOME/.local/bin"
desktop_dir="$HOME/.local/share/applications"

app_path="$app_dir/$app_name"
desktop_file="$desktop_dir/$app_name.desktop"

die() {
    echo "Error: $*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

get_latest_appimage_url() {
    curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep '"browser_download_url":' \
        | grep 'AppImage"' \
        | cut -d '"' -f 4 \
        | head -n 1
}

install_appimage() {
    local url
    local tmp_file

    url="$(get_latest_appimage_url)"
    [ -n "$url" ] || die "Could not find Obsidian AppImage release."

    tmp_file="$(mktemp)"

    echo "Downloading Obsidian..."
    curl -fL "$url" -o "$tmp_file"

    chmod +x "$tmp_file"
    mv "$tmp_file" "$app_path"
}

create_desktop_entry() {
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Name=Obsidian
Exec=$app_path
Type=Application
Categories=Office;Utility;
Terminal=false
EOF
}

main() {
    require_command curl
    require_command grep
    require_command cut
    require_command mktemp

    mkdir -p "$app_dir" "$desktop_dir"

    install_appimage
    create_desktop_entry

    echo "Obsidian installed."
    echo "Command: $app_path"
}

main "$@"
