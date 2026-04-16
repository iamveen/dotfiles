# Preferred tools

Always use these tools over their standard equivalents:

- `rg` instead of `grep -r` for searching code
- `fd` instead of `find` for finding files
- `sd` instead of `sed` for find & replace
- `jq` for parsing/filtering JSON
- `sg` (ast-grep) for structural code search instead of pattern grep
- `difft`/`dft` instead of `git diff`
- `hyperfine` instead of `time` for benchmarking

Use when relevant:

- `yq` for YAML, TOML, XML configs
- `bat` for viewing files with syntax highlighting
- `delta` for git log/diff output
- `tokei` for language breakdown stats
- `watchexec` for running commands on file change
