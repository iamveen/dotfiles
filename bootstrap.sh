#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ── Platform detection ───────────────────────────────────────────────────
detect_platform() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian)  echo "ubuntu" ;;
            alpine)         echo "alpine" ;;
            arch)           echo "arch" ;;
            *)              echo "unknown" ;;
        esac
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# ── Install minimal prerequisites ────────────────────────────────────────
install_deps() {
    if command -v apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        sudo apt-get -qq update
        sudo apt-get -qq install -y curl sudo >/dev/null 2>&1
    elif command -v apk &>/dev/null; then
        sudo apk add --no-cache curl sudo >/dev/null 2>&1
    elif command -v brew &>/dev/null; then
        true  # macOS typically has curl already
    fi

    # Install uv if not present
    if ! command -v uv &>/dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
}

# ── Run Ansible playbook ────────────────────────────────────────────────
run_playbook() {
    local platform="$1"
    local playbook="$SCRIPT_DIR/playbooks/${platform}.yml"

    if [[ ! -f "$playbook" ]]; then
        echo "Error: no playbook found for platform '$platform' ($playbook)" >&2
        exit 1
    fi

    echo "Running Ansible playbook: playbooks/${platform}.yml"
    uvx --from ansible-core ansible-playbook -c local -i localhost, "$playbook"
}

# ── Symlink dotfiles with stow ───────────────────────────────────────────
run_stow() {
    if [[ ! -d "$SCRIPT_DIR/stow" ]]; then
        echo "No stow/ directory found, skipping symlink step."
        return
    fi
    echo "Symlinking dotfiles with stow..."
    (cd "$SCRIPT_DIR/stow" && stow --target ~ .)
}

# ── Main ─────────────────────────────────────────────────────────────────
main() {
    platform="$(detect_platform)"
    echo "Detected platform: $platform"

    install_deps
    run_playbook "$platform"
    run_stow
}

main "$@"
