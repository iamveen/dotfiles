#!/usr/bin/env bash
set -euo pipefail

# Resolve paths relative to the script location
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"

IMAGE=${IMAGE:-dotfiles-test-ubuntu}
CONTAINER=${CONTAINER:-dotfiles-test}

usage() {
    cat <<EOF
Usage: $(basename "$0") <command>

Commands:
  build              Build the Docker image
  run                Rebuild image and run interactive ephemeral container
  start              Rebuild image and start a detached background container
  exec [cmd...]      Exec into the running container (starts if needed)
  stop               Force stop and remove the container
  help               Show this help message
EOF
}

cmd_build() {
    docker build -t "$IMAGE" "$SCRIPT_DIR"
}

cmd_run() {
    cmd_build
    docker run --rm -it \
        -v "$DOTFILES_DIR":/home/"$(id -un)"/.dotfiles \
        "$IMAGE"
}

cmd_start() {
    cmd_build
    docker run -d --name "$CONTAINER" \
        -v "$DOTFILES_DIR":/home/"$(id -un)"/.dotfiles \
        "$IMAGE" sleep infinity
}

cmd_exec() {
    if ! docker ps --filter "name=^/${CONTAINER}$" --format '{{.Names}}' | grep -q .; then
        echo "Container not running, starting..." >&2
        cmd_start
    fi

    # Only allocate TTY when stdout is a terminal
    local tty_flag=""
    [[ -t 1 ]] && tty_flag="-t"

    exec docker exec -i $tty_flag "$CONTAINER" "$@"
}

cmd_stop() {
    docker rm -f "$CONTAINER"
}

# Dispatch
command=${1:-help}
shift || true

case "$command" in
    build) cmd_build ;;
    run)   cmd_run ;;
    start) cmd_start ;;
    exec)  cmd_exec "$@" ;;
    stop)  cmd_stop ;;
    help|--) usage ;;
    *)     echo "Unknown command: $command" >&2; usage >&2; exit 1 ;;
esac
