# Trusted Dev Setup - Architecture

## Problem

Trusted engineering projects use `bin/setup` scripts written in Ruby to configure project-level dependencies (credentials, gems, npm packages, database). However, running `bin/setup` requires Ruby, which requires mise, which requires Homebrew (on macOS) or apt/pacman (on Linux), which requires the repo to be cloned, which requires git and gh.

This is a chicken-and-egg problem: you need the repo cloned to run `bin/setup`, but you need the tools that `bin/setup` depends on to exist before you can clone and run it.

## Solution

A centralized `trusted/devsetup` repository containing a bash bootstrap script (`setup.sh`) that prepares any developer machine with the baseline system tools required to clone and run any Trusted project's `bin/setup`.

The script is invocable via `curl | bash` on a fresh machine (no prerequisites beyond bash and curl, which are present on all target platforms).

## Architecture

### Two-layer setup model

1. **System bootstrap (this repo)**: Installs tool managers and core CLI tools. Written in bash. Runs before any project repo is cloned.
2. **Project setup (each repo's `bin/setup`)**: Installs project-specific dependencies, credentials, and configuration. Written in Ruby. Runs after the repo is cloned.

### Boundary rule

The bootstrap script installs **tool managers and CLI tools**, not language runtimes tied to specific projects. The one exception is Ruby: a global "latest stable" Ruby is installed via mise so that Ruby-based `bin/setup` scripts can execute. Projects pin their own Ruby version via `.mise.toml` / `.tool-versions`, and mise handles the switch automatically when entering the project directory.

## Target platforms

| Platform                  | Package manager | Notes                             |
| ------------------------- | --------------- | --------------------------------- |
| macOS                     | Homebrew        | Primary development platform      |
| Ubuntu (Desktop & Server) | apt             | CI, codespaces, some dev machines |
| Arch Linux / Omarchy      | pacman          | Omarchy users                     |

## Tools installed

The bootstrap installs the following, in order:

1. **Package manager**: Homebrew (macOS) / apt update (Ubuntu) / pacman -Syu (Arch)
2. **git**: Version control (usually pre-installed, but ensured)
3. **gh**: GitHub CLI for repo cloning and authentication
4. **gh auth**: Interactive GitHub authentication (`gh auth login`)
5. **mise**: Version manager for Ruby, Node, and other runtimes
6. **ruby** (latest stable, via mise): Global default so `bin/setup` scripts work
7. **op**: 1Password CLI for secrets management

### What is NOT installed

- Node.js (left to individual projects via mise)
- Project-specific Ruby versions (handled by mise + `mise.toml` per project)
- Any project dependencies (gems, npm packages, databases)

## Idempotency

The base setup section is fully idempotent. Running `setup.sh` multiple times produces the same result. Each tool installation checks whether the tool already exists before attempting to install it.

## Migrations

Migrations handle one-time transitions that are not naturally idempotent: removing deprecated tools, changing configuration formats, renaming state files, etc.

### Design

Inspired by [Omarchy's migration system](https://github.com/basecamp/omarchy/blob/dev/bin/omarchy-migrate).

- Migration scripts live in `migrations/` and are named with a Unix timestamp: `1740000000.sh`
- State is tracked in `~/.local/state/trusted/devsetup/migrations/` as empty marker files (one per completed migration)
- On each run of `setup.sh`, the migration runner:
  1. Scans `migrations/*.sh` sorted numerically
  2. Skips any migration whose marker file already exists
  3. Executes pending migrations in order
  4. Creates marker file on success
  5. Stops on failure (does not skip or continue)
- Migrations are written in bash (they run as part of the bootstrap layer)
- Once shipped and run by engineers, migrations are **immutable**. If a migration was wrong, ship a corrective migration.

### Creating a new migration

```bash
# Generate a migration file named with the current Unix timestamp
date +%s  # e.g., 1740000000
touch migrations/1740000000.sh
chmod +x migrations/1740000000.sh
```

### Re-running a migration

```bash
setup.sh --rerun 1740000000
```

This removes the marker file for the given migration and re-executes it.

## State directory

All local state is stored under `~/.local/state/trusted/devsetup/` (follows XDG Base Directory conventions):

```
~/.local/state/trusted/devsetup/
└── migrations/
    ├── 1740000000.sh    # marker: migration completed
    ├── 1740100000.sh
    └── ...
```

## CLI interface

```
Usage: setup.sh [OPTIONS]

Options:
  --rerun <timestamp>    Re-run a specific migration by its timestamp
  --help                 Show usage information

Examples:
  # First-time setup (or re-run to update)
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/devsetup/main/setup.sh)"

  # Re-run a specific migration
  ./setup.sh --rerun 1740000000
```

## End-to-end developer flow

```bash
# 1. One-time system bootstrap
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/trusted/devsetup/main/setup.sh)"

# 2. Clone any Trusted project
gh repo clone trusted/<project>

# 3. Project-specific setup
cd <project> && bin/setup
```

## Repository structure

```
devsetup/
├── setup.sh              # Main bootstrap script (bash, entry point)
├── lib/
│   └── migrate.sh        # Migration runner (sourced by setup.sh)
├── migrations/           # Run-once transition scripts
│   └── .gitkeep
├── test/
│   └── setup_test.bats   # Post-setup verification tests (bats-core)
├── .github/
│   └── workflows/
│       └── ci.yml        # GitHub Actions: shellcheck + Ubuntu setup + tests
├── ARCHITECTURE.md       # This file
├── README.md             # Brief usage instructions
├── AGENTS.md             # Guidelines for AI agents modifying this repo
└── .gitignore
```

## Design principles

1. **Bash only**: The bootstrap layer uses only bash and standard Unix tools. No Ruby, Python, or other runtime dependencies.
2. **Idempotent base, run-once migrations**: The base setup is safe to re-run. Migrations execute exactly once per machine.
3. **Fail fast**: `set -euo pipefail`. If something fails, stop immediately. Don't leave the machine in a half-configured state.
4. **Defensive migrations**: Each migration checks its own preconditions. Never assume prior state.
5. **Immutable migrations**: Once shipped, never edit a migration. Ship a new one instead.
6. **Minimal scope**: Install tool managers, not tools. The one exception (Ruby) exists to solve the bootstrap problem.
7. **Single command**: Engineers should only need to remember one command to set up or update their machine.
