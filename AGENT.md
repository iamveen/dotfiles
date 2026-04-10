# Agent Instructions for dotfiles

## Pre-Commit: Secret Detection

Before every commit, check staged files for potential secrets.

### What to scan for
- API keys (patterns like `sk-`, `api_key`, `apikey`, `api-key`)
- Tokens containing `_TOKEN`, `SECRET`, `PASSWORD`, `PRIVATE_KEY`
- High-entropy strings that look like secrets
- URLs with embedded credentials (`https://user:pass@...`)

### Files to ignore
- `.pi/AGENT.md` itself
- Documentation examples using placeholder values
- Test fixtures explicitly designed as examples

### If secrets are found
**DO NOT commit.** Instead:
1. Warn the user about the detected potential secret
2. Show the file and line where it was found
3. Suggest remediation steps:
   - Move secrets to `.local.toml`, `.env.local`, or shell environment
   - Use `git add --patch` to exclude the sensitive line if appropriate
   - Add to `.gitignore` if the file should never be tracked

### If no secrets found
Proceed with the commit as normal.

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
