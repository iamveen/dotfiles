# Scripts

A single `install.sh` handles everything — bootstrapping a fresh machine and
re-applying config on an existing one.

## Usage

```sh
# Fresh machine, as root
curl -fsSL https://raw.githubusercontent.com/iamveen/dotfiles/main/scripts/install.sh | sh

# Fresh machine, as root, with docker
curl -fsSL https://raw.githubusercontent.com/iamveen/dotfiles/main/scripts/install.sh | sh -s -- --docker

# Already cloned, re-apply
sh ~/.dotfiles/scripts/install.sh
sh ~/.dotfiles/scripts/install.sh --docker
```

## Flow

```mermaid
flowchart TD
    A([Start]) --> B{Running as root?}

    B -->|Yes| C[apt install sudo]
    C --> D{User iamveen exists?}
    D -->|No| E[Create iamveen\nConfigure passwordless sudo]
    D -->|Yes| F[Re-exec as iamveen]
    E --> F

    B -->|No| G{git installed?}
    F --> G
    G -->|No| H[sudo apt install git]
    G -->|Yes| I{~/.dotfiles exists?}
    H --> I
    I -->|No| J[Clone repo\nRe-exec from repo]
    I -->|Yes| K[Install system packages]
    J --> K
    K --> L[Enable unattended-upgrades]
    L --> M[Install fish + set default shell]
    M --> N[Install nushell]
    N --> O[Install mise]
    O --> P[Stow dotfiles]
    P --> Q[mise install]
    Q --> R{--docker flag?}
    R -->|Yes| S[Install Docker + docker-agent]
    R -->|No| T
    S --> T([Done])
```
