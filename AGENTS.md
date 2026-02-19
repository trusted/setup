# AGENTS.md

Guidance for AI coding agents working on the Trusted Dev Setup repository.

## Overview

This repo contains a bash bootstrap script that prepares developer machines with baseline system tools. It is the first thing a new engineer runs — before any project repo is cloned. Reliability and simplicity are paramount.

## Architecture

- `setup.sh` — Main entry point. Bash only. Detects OS, installs tools idempotently, then runs pending migrations.
- `lib/migrate.sh` — Migration runner. Sourced by `setup.sh`. Tracks state in `~/.local/state/trusted/devsetup/migrations/`.
- `migrations/*.sh` — Run-once bash scripts for environment transitions. Named by Unix timestamp.

## Key rules

### Language

- **All scripts must be bash.** No Ruby, Python, or other runtimes. The whole point of this repo is to bootstrap those runtimes — they cannot be assumed to exist.
- Use POSIX-compatible constructs where practical, but bash-specific features (`[[ ]]`, arrays, `set -euo pipefail`) are acceptable since bash is the target shell.

### Idempotency

- The base setup section in `setup.sh` must be fully idempotent. Every tool installation must check `cmd_exists` (or equivalent) before attempting to install.
- Never assume a tool is missing. Never assume a tool is present. Always check.

### Migrations

- Migrations are for **one-time transitions** that are not naturally idempotent: removing deprecated tools, renaming config files, changing state directory structure, etc.
- Do NOT put idempotent "ensure X is installed" logic in migrations. That belongs in the base setup section of `setup.sh`.
- Migration filenames are `<timestamp>_<description>.sh` — a Unix timestamp followed by a short snake_case description. Example: `1740000000_remove_deprecated_tool.sh`. Generate the timestamp with `date +%s`.
- **Migrations are immutable once merged.** Never edit a shipped migration. Ship a corrective migration instead.
- Each migration must be **self-contained and defensive** — check preconditions, don't assume prior state.
- Migrations must work on all supported platforms (macOS, Ubuntu, Arch) or explicitly check the OS and skip gracefully.

### Platform support

Three platforms are supported. All changes must account for all three:

| Platform      | Detection                                                  | Package manager |
| ------------- | ---------------------------------------------------------- | --------------- |
| macOS         | `uname -s` = `Darwin`                                      | `brew`          |
| Ubuntu/Debian | `/etc/os-release` ID = `ubuntu` or `debian`                | `apt-get`       |
| Arch/Omarchy  | `/etc/os-release` ID = `arch`, `endeavouros`, or `manjaro` | `pacman`        |

When adding a new tool installation, provide install commands for all three platforms.

### Scope boundaries

This repo installs **tool managers, CLI tools, and infrastructure dependencies**:

- Package managers (Homebrew, apt, pacman)
- git, gh, mise, op, circleci
- Ruby (latest stable via mise, as global default for `bin/setup` scripts)
- Node.js (latest LTS via mise, as global default)
- Yarn (via corepack, ships with Node.js)
- Build essentials
- Docker, Docker Compose, Colima (macOS only)
- AWS CLI, AWS VPN Client
- Private registry configuration (Bundler for gems, Yarn for npm scopes)

It does **NOT** install:

- Python or other runtimes (left to project `bin/setup` via mise)
- Project-specific Ruby or Node.js versions (handled by mise + `.mise.toml`)
- Application dependencies (gems, npm packages)
- Databases, Redis, Elasticsearch, etc.
- Editor configurations or dotfiles
- AWS credentials or VPN profiles

### Error handling

- `set -euo pipefail` is set at the top of `setup.sh`. Do not disable it.
- If a migration fails, the runner stops. It does not skip or continue.
- Provide clear error messages with actionable next steps.

### Verification (doctor.sh)

- `doctor.sh` is a read-only diagnostic script that verifies all tools installed by `setup.sh` are present and working. It never modifies anything.
- CI runs on every PR via GitHub Actions (`.github/workflows/ci.yml`).
- **Shellcheck** lints all bash scripts (including `doctor.sh`).
- **Setup (Ubuntu)** runs `setup.sh` end-to-end on an Ubuntu runner, then runs `doctor.sh` to verify.
- When adding a new tool to `setup.sh`, add a corresponding check in `doctor.sh`.
- Before merging changes, verify the script runs cleanly on at least macOS (the primary dev platform).

## Commands

- `shellcheck -x setup.sh doctor.sh lib/*.sh ci/mock-op` — Lint bash scripts
- `bash -n setup.sh` — Check for syntax errors without executing
- `bash doctor.sh` — Run post-setup diagnostic checks
- `date +%s` — Generate a migration timestamp

## Code style

- Use `fmt_header`, `fmt_ok`, and `fmt_install` for user-facing output.
- Use `cmd_exists` to check for tool presence.
- Use `case "$OS"` blocks for platform-specific logic.
- Keep functions small and focused.
- Comment non-obvious decisions, especially platform-specific workarounds.
