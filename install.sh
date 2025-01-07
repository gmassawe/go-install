#!/usr/bin/env bash
#
# Script to install Golang on macOS
# Supports both system-wide and user-only installations
# Author: George Massawe <hi@gmassawe.com>
# Github: https://github.com/gmassawe

set -euo pipefail

#
# Constants
#
LATEST_GO_URL="https://go.dev/dl/"
INSTALL_DIR=""
TEMP_DIR="$(mktemp -d)"
LOCK_FILE="/tmp/golang_install.lock"
SUPPORTED_SHELLS=(".zshrc" ".bashrc" ".bash_profile")

#
# Cleanup
#
trap 'rm -rf "${TEMP_DIR}" "${LOCK_FILE}"' EXIT

#
# Utility functions
#
info() {
    printf "[>] %s\n" "$*" >&2
}

error() {
    printf "[ERROR]: %s\n" "$*" >&2
    rm -rf "${TEMP_DIR}" "${LOCK_FILE}"
    exit 1
}

#
# Pre-installation checks
#
check_dependencies() {
    for cmd in curl tar shasum; do
        if ! command -v "$cmd" &>/dev/null; then
            error "$cmd is required but not installed. Please install it and re-run the script."
        fi
    done
}

acquire_lock() {
    if ! mkdir "${LOCK_FILE}" 2>/dev/null; then
        error "Another instance of the script is running."
    fi
}

#
# Version management
#
get_latest_version() {
    local version
    version=$(curl -sSL "$LATEST_GO_URL" | 
        grep -o 'go[0-9]\+\.[0-9]\+\.[0-9]\+\.darwin-amd64\.tar\.gz' |
        head -n 1 | 
        sed -E 's/go([0-9]+\.[0-9]+\.[0-9]+)\.darwin.*/\1/') || 
        error "Failed to fetch latest version"
    echo "$version"
}

prompt_version() {
    local latest_version="$1"
    local selected_version
    
    printf "The latest version of Go is %s.\n" "$latest_version" >&2
    printf "Enter the version you want to install (default: %s): " "$latest_version" >&2
    read -r selected_version
    
    if [ -z "$selected_version" ]; then
        echo "$latest_version"
    else
        echo "$selected_version"
    fi
}

validate_version() {
    local version="$1"
    if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "Invalid version format. Expected format: X.Y.Z (e.g., 1.23.4)"
    fi
}

#
# Installation type management
#
prompt_install_type() {
    local install_type
    while true; do
        printf "Select installation type:\n" >&2
        printf "1) System-wide installation (requires sudo)\n" >&2
        printf "2) User-only installation\n" >&2
        printf "Enter your choice (1 or 2): " >&2
        read -r choice
        
        case "$choice" in
            1)
                echo "system"
                return
                ;;
            2)
                echo "user"
                return
                ;;
            *)
                printf "Invalid choice. Please enter 1 or 2.\n" >&2
                ;;
        esac
    done
}

setup_install_dir() {
    local install_type="$1"
    if [ "$install_type" = "system" ]; then
        INSTALL_DIR="/usr/local/go"
        if ! sudo -v; then
            error "sudo access is required for system-wide installation."
        fi
    else
        INSTALL_DIR="$HOME/.local/go"
        mkdir -p "$HOME/.local" || error "Failed to create user local directory"
    fi
}

#
# Installation functions
#
uninstall_golang() {
    local install_type="$1"
    
    if [ "$install_type" = "system" ]; then
        if [ -d "/usr/local/go" ]; then
            info "Removing existing system-wide Go installation..."
            sudo rm -rf "/usr/local/go" || error "Failed to remove existing Go installation"
        fi
        
        if brew list --cask golang &>/dev/null; then
            info "Removing Go installed via Homebrew..."
            brew uninstall --cask golang || info "Failed to uninstall Homebrew Go (non-fatal)"
        fi
    else
        if [ -d "$HOME/.local/go" ]; then
            info "Removing existing user Go installation..."
            rm -rf "$HOME/.local/go" || error "Failed to remove existing Go installation"
        fi
    fi
}

download_and_install() {
    local version="$1"
    local install_type="$2"
    local tarball="go${version}.darwin-amd64.tar.gz"
    local url="https://go.dev/dl/${tarball}"
    
    cd "${TEMP_DIR}" || error "Failed to enter temporary directory"
    
    # Download the file first
    info "Downloading Go ${version}..."
    curl -sSLO "$url" || error "Failed to download Go"
    
    # Get the checksum and verify
    info "Verifying download..."
    local download_page
    download_page=$(curl -sSL "https://go.dev/dl/") || error "Failed to fetch download page"
    
    local expected_sha256
    expected_sha256=$(echo "$download_page" | 
        grep -A 5 "${tarball}" | 
        grep -Eo '[0-9a-f]{64}' | 
        head -n 1) || error "Failed to extract checksum"
    
    if [ -z "$expected_sha256" ]; then
        error "Could not find checksum for Go ${version}"
    fi
    
    info "Computing checksum..."
    local computed_sha256
    computed_sha256=$(shasum -a 256 "${tarball}" | cut -d' ' -f1) || error "Failed to compute checksum"
    
    if [ "$computed_sha256" != "$expected_sha256" ]; then
        error "Checksum verification failed"
    fi
    
    info "Installing Go ${version}..."
    if [ "$install_type" = "system" ]; then
        sudo tar -C /usr/local -xzf "$tarball" || error "Failed to extract tarball"
    else
        tar -C "$HOME/.local" -xzf "$tarball" || error "Failed to extract tarball"
    fi
}

update_path() {
    local install_type="$1"
    local updated=false
    local go_path
    
    if [ "$install_type" = "system" ]; then
        go_path='export PATH=/usr/local/go/bin:$PATH'
    else
        go_path='export PATH=$HOME/.local/go/bin:$PATH'
    fi
    
    for shell_rc in "${SUPPORTED_SHELLS[@]}"; do
        local profile_file="$HOME/${shell_rc}"
        if [ -f "$profile_file" ]; then
            if ! grep -q "$go_path" "$profile_file"; then
                info "Updating PATH in ${profile_file}..."
                cp "$profile_file" "${profile_file}.bak" || error "Failed to backup ${profile_file}"
                echo -e "\n# Golang PATH\n${go_path}" >>"$profile_file"
                updated=true
            fi
        fi
    done
    
    if [ "$updated" = false ]; then
        info "No shell profile found/updated. Please add manually:\n${go_path}"
    fi
}

verify_installation() {
    local install_type="$1"
    info "Verifying Go installation..."
    
    local go_cmd
    if [ "$install_type" = "system" ]; then
        go_cmd="/usr/local/go/bin/go"
    else
        go_cmd="$HOME/.local/go/bin/go"
    fi
    
    if ! "$go_cmd" version &>/dev/null; then
        error "Go installation verification failed"
    fi
    
    if ! "$go_cmd" env &>/dev/null; then
        error "Go environment verification failed"
    fi
    
    info "Go installed successfully: $("$go_cmd" version)"
}

#
# Main function
#
main() {
    check_dependencies
    acquire_lock
    
    local install_type
    install_type=$(prompt_install_type)
    setup_install_dir "$install_type"
    
    local latest_version
    latest_version=$(get_latest_version)
    
    local selected_version
    selected_version=$(prompt_version "$latest_version")
    validate_version "$selected_version"
    
    info "Selected Go version: ${selected_version}"
    info "Installation type: ${install_type}"
    
    uninstall_golang "$install_type"
    download_and_install "$selected_version" "$install_type"
    update_path "$install_type"
    verify_installation "$install_type"
    
    info "Installation completed. Restart your terminal or source your shell profile to apply changes."
}

main "$@"
