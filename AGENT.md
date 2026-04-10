# Agent Instructions for dotfiles

## Secret Detection with Gitleaks

A pre-commit hook in `stow/git/.config/git/hooks/pre-commit` runs `gitleaks detect --staged` to catch secrets before they're committed.

### If gitleaks finds secrets
**DO NOT commit.** Instead:
1. Warn the user about the detected potential secret
2. Show `cat /tmp/gitleaks-report.json` for details
3. Suggest remediation steps:
   - Remove the secret from your changes
   - Add false-positive allowlist rules to `.gitleaks.toml`
   - Use `git add --patch` to exclude specific lines
   - Run `git commit --no-verify` to bypass (not recommended)

### If gitleaks is not installed
Install it via `mise install` or commit without detection (warn the user).

### Manual scan
```bash
gitleaks detect --source . --staged --no-git
```

## Repository Structure

- `bootstrap.sh` - Entry point for new machine setup
- `playbooks/` - Ansible playbooks for system provisioning
- `stow/` - Dotfile packages managed by GNU Stow
  - Each subdirectory becomes a package stowed to `$HOME`
- `test/` - Docker-based testing environment

## Common Tasks

### Adding a new dotfile package
```bash
mkdir -p stow/<package>/.config/<app>
cp ~/.config/<app>/config stow/<package>/.config/<app>/
cd stow && stow <package>
```

### Testing changes
```bash
./test/test.sh build
./test/test.sh run
```
