# Nix Setup

Declarative, reproducible system configuration using NixOS + Home Manager + Flakes.
One repo describes every machine, every user environment, and every project dependency.

---

## How it works in one paragraph

`flake.nix` is the entry point. It defines named NixOS machine configurations
(`nixosConfigurations`) and a Home Manager user configuration (`homeConfigurations`).
Each machine imports a set of **profiles** — composable modules that enable services,
install packages, and configure the system. The user environment (dotfiles, global
packages, app configs) is managed by Home Manager and shared across all machines.
Project-specific dependencies live in per-project `flake.nix` files and activate
automatically when you `cd` into the directory via `direnv`.

---

## File layout

```
~/.dotfiles/
├── flake.nix                   # entry point — defines all machines and user env
├── flake.lock                  # pinned nixpkgs + dependency versions (commit this)
│
├── hosts/                      # one directory per machine
│   ├── dev-server/
│   │   └── default.nix         # imports profiles, sets hostname, hardware config
│   ├── pi/
│   │   └── default.nix
│   └── vm/
│       └── default.nix         # lightweight target for local dev VM
│
├── profiles/                   # composable units — import any combination
│   ├── base.nix                # always imported: locale, ssh, firewall, users
│   ├── development.nix         # git, build tools, languages, mise, direnv
│   ├── docker.nix              # docker daemon + user group membership
│   └── xrdp.nix                # remote desktop
│
├── home/                       # Home Manager — user environment
│   ├── default.nix             # sets username/homedir, wires up symlinks
│   └── packages.nix            # global packages always in PATH
│
└── files/                      # all config files, symlinked directly into $HOME
    ├── fish/
    │   ├── config.fish
    │   └── functions/
    ├── git/
    │   └── config
    └── claude/
        └── settings.json
```

`home/` handles two things only: the package list, and declaring which files from
`files/` get symlinked where. All config files live in `files/` as plain text —
edit any of them directly, changes take effect immediately, no rebuild. This is the
same model as the old `stow/` directory.

---

## Creating a new server

Boot the NixOS ISO, partition the disk, then:

```bash
# From the installer environment — pulls config directly from the repo
nixos-install --flake github:yourusername/dotfiles#dev-server
reboot
```

The machine comes up with your user, your shell, your global packages, and all
services configured. First SSH in and run:

```bash
home-manager switch --flake ~/.dotfiles#gavin
```

That's it. Total time from bare metal to working environment: ~10 minutes plus
download time.

**Installing over an existing machine** (without reinstalling) using `nixos-anywhere`:

```bash
# Run from your local machine — installs NixOS over SSH onto a remote target
nix run github:nix-community/nixos-anywhere -- --flake .#dev-server root@<ip>
```

---

## Modifying how a server is configured

Edit the host file or the profile it imports:

```nix
# hosts/dev-server/default.nix
{ ... }: {
  imports = [
    ../../profiles/base.nix
    ../../profiles/development.nix
    ../../profiles/docker.nix      # ← add or remove profiles here
  ];

  networking.hostName = "dev-server";
  time.timeZone = "America/Toronto";

  # machine-specific overrides go here
  services.openssh.ports = [ 2222 ];
}
```

Apply the change:

```bash
# On the machine itself
sudo nixos-rebuild switch --flake ~/.dotfiles#dev-server

# Or push from your local machine to a remote host
nixos-rebuild switch --flake .#dev-server --target-host gavin@dev-server --use-remote-sudo
```

The old system generation is kept. If anything breaks:

```bash
sudo nixos-rebuild switch --rollback
```

Or choose a generation from the boot menu — every generation is a bootable snapshot.

---

## Modifying global user packages

Edit `home/packages.nix`:

```nix
home.packages = with pkgs; [
  ripgrep
  fd
  jq
  tree
  htop
  ruby_3        # ← add or remove here
  nodejs_22
  python313
];
```

Apply:

```bash
home-manager switch --flake ~/.dotfiles#gavin
```

The new packages are in PATH immediately. Old generations are kept — roll back with:

```bash
home-manager generations        # list generations
home-manager rollback           # switch to previous
```

---

## Modifying app configuration

### git, SSH — structured config via Home Manager

These live in `home/git.nix` as Nix expressions. Change them by editing the file
and running `home-manager switch`:

```nix
# home/git.nix
programs.git = {
  enable = true;
  userName = "Gavin Dunne";
  userEmail = "g@veen.ca";
  extraConfig.pull.rebase = true;
};
```

### fish, claude — plain files, live editing

These are symlinked directly from `files/` into `$HOME` using `mkOutOfStoreSymlink`.
Edit them like normal files — changes take effect immediately, no rebuild:

```bash
# Editing this file IS editing ~/.config/fish/config.fish
vim ~/.dotfiles/files/fish/config.fish

# Fish picks up the change immediately (or source it manually)
source ~/.config/fish/config.fish
```

Same for Claude settings:

```bash
vim ~/.dotfiles/files/claude/settings.json   # live, no rebuild needed
```

Git tracks all changes. Commit when you're happy.

---

## Project-specific dependencies

Each project has its own `flake.nix` declaring its dependencies:

```nix
# ~/projects/myapp/flake.nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.ruby_4        # shadows global ruby_3 while inside this project
          pkgs.bundler
          pkgs.postgresql_16
        ];

        # env vars and shell hooks
        PGDATA = "./tmp/postgres";
        shellHook = ''
          echo "myapp dev environment ready"
        '';
      };
    };
}
```

Add a `.envrc` to the project root:

```bash
echo "use flake" > .envrc
direnv allow
```

From that point on, `cd` into the project and the packages activate automatically.
`cd` out and they're gone. Your global tools (`git`, `ripgrep`, etc.) remain available
inside every project shell — the devShell adds to your PATH, it doesn't replace it.

```
~                       → ruby 3.x (global)
~/projects/myapp        → ruby 4.x (project), everything else still available
~/projects/other        → back to ruby 3.x
```

**No per-project config for direnv** — once you've run `direnv allow` once, it's automatic forever. The `flake.lock` in each project pins exact versions, so `git clone` + `direnv allow` gives every contributor the identical environment.

---

## Profiles — composable configurations

A profile is just a NixOS module. Any combination can be imported into any host.

```nix
# profiles/docker.nix
{ pkgs, ... }: {
  virtualisation.docker.enable = true;
  virtualisation.docker.daemon.settings.log-driver = "local";
  users.users.gavin.extraGroups = [ "docker" ];
  home-manager.users.gavin.home.packages = [ pkgs.docker-compose ];
}
```

```nix
# profiles/xrdp.nix
{ pkgs, ... }: {
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  networking.firewall.allowedTCPPorts = [ 3389 ];
}
```

Compose them freely per host:

```nix
# hosts/dev-server/default.nix — development + docker, no desktop
imports = [ ../../profiles/base.nix ../../profiles/development.nix ../../profiles/docker.nix ];

# hosts/workstation/default.nix — development + remote desktop, no docker
imports = [ ../../profiles/base.nix ../../profiles/development.nix ../../profiles/xrdp.nix ];

# hosts/pi/default.nix — minimal, just base
imports = [ ../../profiles/base.nix ];
```

Profile changes apply to every host that imports the profile on next rebuild.
Host-specific overrides always win over profile defaults (standard NixOS module
precedence rules).

---

## VM and Docker targets

### NixOS VM (for local testing)

Build and run a QEMU VM of any host configuration:

```bash
# Build the VM
nix build .#nixosConfigurations.dev-server.config.system.build.vm

# Run it (opens a QEMU window or use -nographic for headless)
./result/bin/run-dev-server-vm
```

The VM shares your `/nix/store` with the host, so it starts in seconds and uses
minimal disk space. Use it to test configuration changes before applying them to
a real machine.

### Docker image

The repo defines a `dockerImage` output — a minimal image with your user environment
pre-installed:

```bash
# Build the image
nix build .#dockerImage

# Load it into Docker
docker load < ./result

# Run it
docker run -it --rm gavin-devenv fish
```

Everything in your `home.packages` is available inside the container. For active
development, mount your project in:

```bash
docker run -it --rm -v $(pwd):/work -w /work gavin-devenv fish
```

### Which to use

| Scenario | Use |
|---|---|
| Testing NixOS config changes safely | VM |
| Isolated project environment, shared kernel | Docker |
| Reproducing a bug in a clean environment | Docker |
| Testing boot/service behaviour | VM |
| CI/CD environments | Docker image from `nix build` |

---

## Version control

`flake.lock` pins every input — nixpkgs, home-manager, any other dependency — to
an exact git commit. Committing `flake.lock` means any checkout of the repo
produces byte-for-byte identical builds.

**Normal workflow:**

```bash
# Make a change
vim home/packages.nix
home-manager switch --flake .#gavin

# Commit when happy
git add home/packages.nix
git commit -m "add ruby_4 globally"
```

**Updating nixpkgs** (to get newer package versions):

```bash
nix flake update          # updates flake.lock to latest nixpkgs
home-manager switch --flake .#gavin   # test it
sudo nixos-rebuild switch --flake .#dev-server
git add flake.lock && git commit -m "bump nixpkgs"
```

**Rolling back** if an update breaks something:

```bash
git revert HEAD           # revert flake.lock to previous pinned versions
home-manager switch --flake .#gavin
```

Or skip git and use the generation system:

```bash
home-manager rollback                 # user env
sudo nixos-rebuild switch --rollback  # system
```

Every deployed generation is kept on disk and bootable until you run
`nix-collect-garbage`. Run garbage collection occasionally to reclaim disk space:

```bash
nix-collect-garbage --delete-older-than 30d
```
