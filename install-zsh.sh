#!/bin/sh
set -eu

install_packages() {
    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y zsh curl git
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zsh curl git
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Syu --needed --noconfirm zsh curl git
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y zsh curl git
    else
        echo "Unsupported package manager."
        exit 1
    fi
}

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        echo "Oh My Zsh is already installed."
        return 0
    fi

    echo "Installing Oh My Zsh..."

    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(
        curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
    )"
}

set_default_shell() {
    ZSH_PATH=$(command -v zsh)

    if [ "${SHELL:-}" = "$ZSH_PATH" ]; then
        echo "Zsh is already your default shell."
        return 0
    fi

    printf '%s' "Make Zsh your default shell? [y/N] "
    read answer

    case "$answer" in
        y|Y|yes|YES)
            chsh -s "$ZSH_PATH"
            echo "Default shell changed to Zsh."
            echo "Log out and back in for the change to take effect."
            ;;
        *)
            echo "Default shell unchanged."
            ;;
    esac
}

main() {
    install_packages

    if command -v zsh >/dev/null 2>&1; then
        zsh --version
    else
        echo "Zsh was not installed correctly."
        exit 1
    fi

    install_oh_my_zsh
    set_default_shell

    echo
    echo "Done. You can start Zsh now with:"
    echo "zsh"
}

main "$@"
