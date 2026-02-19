#!/usr/bin/env bats
#
# Post-setup verification tests.
# Run after setup.sh completes to validate all tools were installed correctly.

# ---------------------------------------------------------------------------
# git
# ---------------------------------------------------------------------------

@test "git is installed" {
  command -v git
}

@test "git reports a version" {
  run git --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"git version"* ]]
}

# ---------------------------------------------------------------------------
# GitHub CLI (gh)
# ---------------------------------------------------------------------------

@test "gh is installed" {
  command -v gh
}

@test "gh reports a version" {
  run gh --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"gh version"* ]]
}

# ---------------------------------------------------------------------------
# mise
# ---------------------------------------------------------------------------

@test "mise is installed" {
  command -v mise
}

@test "mise reports a version" {
  run mise --version
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Ruby (via mise)
# ---------------------------------------------------------------------------

@test "ruby is available via mise" {
  run mise which ruby
  [ "$status" -eq 0 ]
}

@test "ruby executes and reports a version" {
  run mise exec -- ruby --version
  [ "$status" -eq 0 ]
  [[ "$output" == *"ruby"* ]]
}

# ---------------------------------------------------------------------------
# 1Password CLI (op)
# ---------------------------------------------------------------------------

@test "op is installed" {
  command -v op
}

@test "op reports a version" {
  run op --version
  [ "$status" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Build essentials
# ---------------------------------------------------------------------------

@test "make is installed" {
  command -v make
}

@test "gcc or cc is installed" {
  command -v gcc || command -v cc
}

# ---------------------------------------------------------------------------
# Migration state
# ---------------------------------------------------------------------------

@test "migration state directory exists" {
  [ -d "$HOME/.local/state/trusted/devsetup/migrations" ]
}

# ---------------------------------------------------------------------------
# Work directory and devsetup clone
# ---------------------------------------------------------------------------

@test "~/Work directory exists" {
  [ -d "$HOME/Work" ]
}

@test "devsetup is cloned to ~/Work/devsetup" {
  [ -d "$HOME/Work/devsetup/.git" ]
}

@test "~/Work/devsetup contains setup.sh" {
  [ -f "$HOME/Work/devsetup/setup.sh" ]
}
