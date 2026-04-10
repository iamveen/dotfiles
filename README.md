# dotfiles

Bootstrap a new development environment from scratch.

```
git clone → bootstrap → done
```

## Quick Start

```bash
git clone https://github.com/user/dotfiles.git ~/.dotfiles
~/.dotfiles/bootstrap.sh
```

`bootstrap.sh` does three things:

1. **Install prerequisites** — the bare minimum to run `uvx`
2. **Run Ansible** — provisions the system (packages, tools, services) via `uvx ansible`
3. **Symlink configs** — uses `stow` (installed by Ansible) to link dotfiles from this repo into your `$HOME`

## File Layout

```
~/.dotfiles/
├── bootstrap.sh            # Entry point: deps → ansible (installs stow) → symlink dotfiles
├── README.md               # This file
├── ansible.cfg             # Ansible configuration
├── playbooks/
│   └── ubuntu.yml          # Ubuntu system setup (single file)
├── stow/                   # Dotfile packages for stow
│   ├── git/
│   │   └── .gitconfig
│   ├── shell/
│   │   ├── .bashrc
│   │   └── .inputrc
│   └── ...
└── test/                   # Docker sandbox for testing
    ├── Dockerfile
    └── test.sh
```

### How `stow/` works

Each subdirectory inside `stow/` is a package. Files are symlinked
relative to `~/.dotfiles/stow/PACKAGE` into your `$HOME`:

```
stow/git/.gitconfig   →   ~/.gitconfig
stow/shell/.bashrc    →   ~/.bashrc
```

## Testing

The `test/` folder spins up a Docker container that mirrors your host
user (matching UID/GID) with the dotfiles repo mounted so you can
safely iterate on playbooks.

```bash
./test/test.sh build          # Build the test image
./test/test.sh run            # Rebuild + ephemeral interactive shell
./test/test.sh start          # Rebuild + start detached container
./test/test.sh exec [cmd...]  # Exec into running container (auto-starts)
./test/test.sh stop           # Force stop and remove
```

## Multi-Distro Plan

Eventually this repo will support multiple OS families. The approach:

- **One playbook per distro**, kept to a single file (`playbooks/<distro>.yml`)
- **Platform detection** in `bootstrap.sh` picks the right playbook
- **Shared `stow/` packages** — configs that work identically everywhere
- **Optional per-distro stow packages** — `stow-shell-ubuntu/`, `stow-shell-alpine/`, etc. for platform-specific configs

Currently supported and planned:

| Platform | Playbook              | Status    |
|----------|-----------------------|-----------|
| Ubuntu   | `playbooks/ubuntu.yml`| ✅ Current |
| Alpine   | `playbooks/alpine.yml`| 🔄 Planned |
| macOS    | `playbooks/macos.yml` | 🔄 Planned |

Platform detection logic in `bootstrap.sh` (planned):

```
Linux + apt  →  playbooks/ubuntu.yml
Linux + apk  →  playbooks/alpine.yml
Darwin       →  playbooks/macos.yml
```

## Prerequisites

- A POSIX shell (`bash` or compatible)
- `sudo` (or root) access
- Internet connection (for package downloads)

Everything else is bootstrapped automatically.
