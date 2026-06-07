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

install_package() {
    local package="$1"

    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y "$package"
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y "$package"
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm "$package"
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y "$package"
    else
        die "Unsupported package manager. Install $package manually."
    fi
}

ensure_command() {
    local command_name="$1"
    local package_name="${2:-$1}"

    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Installing missing dependency: $package_name"
        install_package "$package_name"
    fi

    command -v "$command_name" >/dev/null 2>&1 || die "Missing required command: $command_name"
}

get_latest_appimage_url() {
    local release_json

    release_json="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest")"

    case "$(uname -m)" in
        x86_64)
            printf '%s\n' "$release_json" |
                jq -r '.assets[]
                | select(.name | test("^Obsidian-[0-9].*\\.AppImage$"))
                | select(.name | contains("arm64") | not)
                | .browser_download_url' |
                head -n 1
            ;;
        aarch64|arm64)
            printf '%s\n' "$release_json" |
                jq -r '.assets[]
                | select(.name | endswith("arm64.AppImage"))
                | .browser_download_url' |
                head -n 1
            ;;
        *)
            die "Unsupported architecture: $(uname -m)"
            ;;
    esac
}

install_appimage() {
    local url
    local tmp_file

    url="$(get_latest_appimage_url)"
    [ -n "$url" ] || die "Could not find a matching Obsidian AppImage."

    tmp_file="$(mktemp)"

    echo "Downloading Obsidian..."
    echo "$url"

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
    ensure_command curl curl
    ensure_command jq jq
    ensure_command mktemp coreutils
    ensure_command uname coreutils

    mkdir -p "$app_dir" "$desktop_dir"

    install_appimage
    create_desktop_entry

    echo
    echo "Obsidian installed."
    echo "Run with:"
    echo "obsidian"
}

main "$@"
