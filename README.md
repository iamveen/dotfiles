# dotfiles

Bootstrap a new development environment from scratch.

```
git clone → dot boot → done
```

## Quick Start

```bash
git clone https://github.com/user/dotfiles.git ~/.dotfiles
~/.dotfiles/bin/dot boot
```

`dot boot` does three things:

1. **Install prerequisites** — curl, sudo, and `uv` via the `dot pre` command
2. **Run Ansible** — provisions the system (packages, tools, services) via `uvx ansible`
3. **Symlink configs** — uses `stow` to link dotfiles from this repo into your `$HOME`

## CLI

```
dot <command>

Commands:
  pre       Install minimal prerequisites (curl, sudo, uv)
  ansible   Run the Ansible playbook for the current platform
  stow      Manage dotfile stow modules
            restow [modules...]  Restow modules (all if none given)
            add <module> <path>  Create a module and move files into it
  boot      Full bootstrap: pre → ansible → stow
```

## File Layout

```
~/.dotfiles/
├── bin/
│   ├── dot                 # Main CLI entry point
│   └── pbcopy              # Helper script
├── playbooks/
│   └── ubuntu.yml          # Ubuntu system setup
├── stow/                   # Dotfile packages for stow
│   ├── fish/
│   ├── git/
│   ├── mise/
│   └── pi/
├── test/                   # Docker sandbox for testing
│   ├── Dockerfile
│   └── test.sh
├── AGENT.md                # Agent instructions
├── ansible.cfg             # Ansible configuration
└── README.md               # This file
```

### How `stow/` works

Each subdirectory inside `stow/` is a package. Files are symlinked
relative to `~/.dotfiles/stow/PACKAGE` into your `$HOME`:

```
stow/git/.gitconfig   →   ~/.gitconfig
stow/mise/.config/mise.toml → ~/.config/mise.toml
```

## Stow Usage

### Restow all modules

```bash
dot stow restow
```

### Restow specific modules

```bash
dot stow restow git fish
```

### Add a new config file

```bash
dot stow add <module> <path>
```

For example, to track an existing file:

```bash
dot stow add git ~/.gitconfig
```

This moves `~/.gitconfig` → `stow/git/.gitconfig` and symlinks it back.

### Remove a config while keeping it tracked

```bash
stow -D git    # deletes ~/.gitconfig symlink
```

The file stays in the repo so you can re-stow it later.

## Testing

The `test/` folder spins up a Docker container that mirrors your host
user (matching UID/GID) with the dotfiles repo mounted so you can
safely iterate on playbooks.

```bash
./test/test.sh build          # Build the test image
./test/test.sh run            # Rebuild + ephemeral interactive shell
./test/test.sh start          # Rebuild + start detached container
./test/test.sh exec [cmd...]  # Exec into running container (auto-starts)
./test/test.sh stop           # Force stop and remove container
```

## Supported Platforms

| Platform | Playbook              | Status    |
|----------|-----------------------|-----------|
| Ubuntu   | `playbooks/ubuntu.yml`| ✅ Current |
| Debian   | `playbooks/ubuntu.yml`| ✅ Current |
| Alpine   | `playbooks/alpine.yml`| 🔄 Planned |
| Arch     | `playbooks/arch.yml`  | 🔄 Planned |
| macOS    | `playbooks/macos.yml` | 🔄 Planned |

Platform detection is automatic — `dot boot` detects your OS and runs the appropriate playbook.

## Prerequisites

- A POSIX shell (`bash` or compatible)
- `sudo` (or root) access
- Internet connection (for package downloads)

Everything else is bootstrapped automatically.