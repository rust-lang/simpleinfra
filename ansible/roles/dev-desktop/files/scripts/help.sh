#!/usr/bin/env bash

echo "# Available scripts for managing your Rust checkouts"
echo "init.sh              | first time setup, you should only have to execute this once on a new machine"
echo "status.sh            | list the branches and git status of all copies of the Rust repo"
echo "new_worktree.sh      | creates a worktree (shallow copy of the main git checkout of Rust, sharing the .git folder)"
echo "detach_merged_prs.sh | invokes \"git pull --fast-forward-only\" on all worktrees and detaches those that are equal to the \"master\" branch"
echo ""
echo "# Rarer commands:"
echo "set_defaults.sh      | connects the global config.toml with all worktrees. Use this when your setup is broken"
echo "setup_rust.sh        | Clone your fork of rust-lang/rust, compile, and then link it"
