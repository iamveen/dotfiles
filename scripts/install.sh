#!/usr/bin/env sh
set -e

REPO="https://github.com/iamveen/dotfiles.git"
RAW_URL="https://raw.githubusercontent.com/iamveen/dotfiles/main/scripts/install.sh"
DOTFILES="/home/iamveen/.dotfiles"
DOCKER=0

for arg in "$@"; do
  case "$arg" in
    --docker) DOCKER=1 ;;
    *) echo "Unknown flag: $arg" && exit 1 ;;
  esac
done

# ── Colours ───────────────────────────────────────────────────────────────────

GRN='\033[1;32m'
RED='\033[1;31m'
YEL='\033[1;33m'
GRY='\033[0;37m'
MAG='\033[1;35m'
WHT='\033[1;37m'
BLU='\033[1;34m'
R='\033[0m'

# ── Status helpers ─────────────────────────────────────────────────────────────

_STATUS_FILE=$(mktemp)
trap 'rm -f "$_STATUS_FILE"' EXIT

skip() {
  printf "%s" "${1:-skipped}" > "$_STATUS_FILE"
}

run() {
  desc="$1"
  fn="$2"
  : > "$_STATUS_FILE"
  tmpout=$(mktemp)

  printf "  ○ %s..." "$desc"

  if "$fn" > "$tmpout" 2>&1; then
    status=$(cat "$_STATUS_FILE")
    if [ -n "$status" ]; then
      printf "\r  ${GRY}—  %s (%s)${R}\n" "$desc" "$status"
    else
      printf "\r  ${GRN}✓${R}  %s\n" "$desc"
    fi
    rm -f "$tmpout"
  else
    printf "\r  ${RED}✗${R}  %s\n\n" "$desc"
    cat "$tmpout"
    printf "\n"
    rm -f "$tmpout"
    exit 1
  fi
}

# ── Banner ────────────────────────────────────────────────────────────────────

print_banner() {
  printf "\n${YEL}"
  printf '  ██╗  ██╗███████╗    ███╗   ███╗ █████╗ ███╗  ██╗\n'
  printf '  ██║  ██║██╔════╝    ████╗ ████║██╔══██╗████╗ ██║\n'
  printf '  ███████║█████╗      ██╔████╔██║███████║██╔██╗██║\n'
  printf '  ██╔══██║██╔══╝      ██║╚██╔╝██║██╔══██║██║╚████║\n'
  printf '  ██║  ██║███████╗    ██║ ╚═╝ ██║██║  ██║██║ ╚███║\n'
  printf "  ╚═╝  ╚═╝╚══════╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚══╝${R}\n"
  printf "\n"
  printf "${WHT}                 /\\ \n"
  printf "                /  \\ \n"
  printf "               / ++ \\ \n"
  printf "              /______\\ \n"
  printf "                 ||\n"
  printf "                 ||\n"
  printf "               ══╧══${R}\n"
  printf "\n"
  printf "${MAG}       ⚡  BY THE POWER OF GRAYSKULL  ⚡${R}\n"
  printf "\n"
  printf "${RED}    ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄\n"
  printf "    █                                       █\n"
  printf "    █   I  H A V E  T H E  P O W E R  !   █\n"
  printf "    █                                       █\n"
  printf "    ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀${R}\n"
  printf "\n"
  printf "${BLU}    github.com/iamveen/dotfiles${R}\n"
  printf "\n"
}

# ── Functions ─────────────────────────────────────────────────────────────────

install_sudo() {
  apt-get update -qq
  apt-get install -y sudo
}

create_user() {
  if ! id iamveen > /dev/null 2>&1; then
    useradd -m -s /bin/bash iamveen
  fi
  echo "iamveen ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/iamveen
  chmod 440 /etc/sudoers.d/iamveen

  SSH_DIR="/home/iamveen/.ssh"
  mkdir -p "$SSH_DIR"
  curl -fsSL https://github.com/iamveen.keys >> "$SSH_DIR/authorized_keys"
  sort -u "$SSH_DIR/authorized_keys" -o "$SSH_DIR/authorized_keys"
  chmod 700 "$SSH_DIR"
  chmod 600 "$SSH_DIR/authorized_keys"
  chown -R iamveen:iamveen "$SSH_DIR"
}

become_user() {
  if [ -f "$DOTFILES/scripts/install.sh" ]; then
    exec su -c "INSTALL_RESUMED=1 sh $DOTFILES/scripts/install.sh $*" iamveen
  else
    exec su -c "INSTALL_RESUMED=1 curl -fsSL $RAW_URL | sh -s -- $*" iamveen
  fi
}

install_git() {
  command -v git > /dev/null 2>&1 && skip "already installed" && return
  sudo apt-get update -qq
  sudo apt-get install -y git
}

install_packages() {
  sudo apt-get update -qq
  sudo apt-get install -y \
    build-essential unzip stow \
    tree entr pkg-config libssl-dev \
    unattended-upgrades
}

enable_unattended_upgrades() {
  sudo systemctl enable --now unattended-upgrades
}

install_fish() {
  if command -v fish > /dev/null 2>&1; then
    skip "already installed"
    return
  fi
  sudo add-apt-repository -y ppa:fish-shell/release-4
  sudo apt-get update -qq
  sudo apt-get install -y fish
  sudo chsh -s /usr/bin/fish "$USER"
}

install_nushell() {
  if command -v nu > /dev/null 2>&1; then
    skip "already installed"
    return
  fi
  if [ ! -f /etc/apt/keyrings/fury-nushell.gpg ]; then
    wget -qO- https://apt.fury.io/nushell/gpg.key \
      | sudo gpg --dearmor -o /etc/apt/keyrings/fury-nushell.gpg
  fi
  echo "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" \
    | sudo tee /etc/apt/sources.list.d/nushell.list > /dev/null
  sudo apt-get update -qq
  sudo apt-get install -y nushell
}

install_mise() {
  command -v mise > /dev/null 2>&1 && skip "already installed" && return
  curl https://mise.run | sh
}

stow_dotfiles() {
  cd "$DOTFILES/stow"
  stow --restow --target="$HOME" */
}

mise_install() {
  mise install
}

install_docker() {
  if command -v docker > /dev/null 2>&1; then
    skip "already installed"
    return
  fi
  ARCH="$(dpkg --print-architecture)"
  sudo apt-get install -y ca-certificates gnupg

  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  fi

  CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $CODENAME stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update -qq
  sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin docker-model-plugin

  sudo systemctl enable --now docker
  sudo usermod -aG docker "$USER"
}

install_docker_agent() {
  ARCH="$(dpkg --print-architecture)"
  LATEST="$(curl -fsSL https://api.github.com/repos/docker/docker-agent/releases/latest \
    | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
  INSTALLED="$(docker-agent version 2>/dev/null | grep -o '[0-9]*\.[0-9]*\.[0-9]*' || echo '0.0.0')"

  if [ "$INSTALLED" = "$LATEST" ]; then
    skip "already at v$LATEST"
    return
  fi

  sudo curl -fsSL \
    "https://github.com/docker/docker-agent/releases/latest/download/docker-agent-linux-$ARCH" \
    -o /usr/local/bin/docker-agent
  sudo chmod +x /usr/local/bin/docker-agent
}

# ── Main ──────────────────────────────────────────────────────────────────────

if [ "$(id -u)" = "0" ]; then
  printf "  ○ Installing sudo...";  install_sudo;  printf "\r  ${GRN}✓${R}  Installing sudo\n"
  printf "  ○ Creating user...";    create_user;   printf "\r  ${GRN}✓${R}  Creating user iamveen\n"
  become_user "$@"
fi

[ "${INSTALL_RESUMED:-0}" = "0" ] && print_banner

run "Installing git"               install_git

if [ ! -d "$DOTFILES" ]; then
  printf "  ○ Cloning dotfiles..."
  tmpout=$(mktemp)
  if git clone "$REPO" "$DOTFILES" > "$tmpout" 2>&1; then
    printf "\r  ${GRN}✓${R}  Cloning dotfiles\n"
    rm -f "$tmpout"
  else
    printf "\r  ${RED}✗${R}  Cloning dotfiles\n\n"
    cat "$tmpout"
    rm -f "$tmpout"
    exit 1
  fi
  exec sh "$DOTFILES/scripts/install.sh" "$@"
fi

run "Installing system packages"   install_packages
run "Enabling auto-upgrades"       enable_unattended_upgrades
run "Installing fish"              install_fish
run "Installing nushell"           install_nushell
run "Installing mise"              install_mise
run "Stowing dotfiles"             stow_dotfiles
run "Installing mise tools"        mise_install

if [ "$DOCKER" = "1" ]; then
  run "Installing Docker"          install_docker
  run "Installing docker-agent"    install_docker_agent
fi

printf "\n${GRN}All done!${R} Open a new shell to pick up fish and mise.\n\n"
