# Worktrunk (wt)

This file is vendored from `max-sixty/worktrunk` to make it easy for agents to
work offline and to standardize our worktree workflow.

Source: https://github.com/max-sixty/worktrunk

---

<!-- Begin vendored README -->

<!-- markdownlint-disable MD033 -->

<h1><img src="docs/static/logo.png" alt="Worktrunk logo" width="50" align="absmiddle">&nbsp;&nbsp;Worktrunk</h1>

[![Docs](https://img.shields.io/badge/docs-worktrunk.dev-blue?style=for-the-badge&logo=gitbook)](https://worktrunk.dev)
[![Crates.io](https://img.shields.io/crates/v/worktrunk?style=for-the-badge&logo=rust)](https://crates.io/crates/worktrunk)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![CI](https://img.shields.io/github/actions/workflow/status/max-sixty/worktrunk/ci.yaml?event=push&branch=main&style=for-the-badge&logo=github)](https://github.com/max-sixty/worktrunk/actions?query=branch%3Amain+workflow%3Aci)
[![Codecov](https://img.shields.io/codecov/c/github/max-sixty/worktrunk?style=for-the-badge&logo=codecov)](https://codecov.io/gh/max-sixty/worktrunk)
[![Stars](https://img.shields.io/github/stars/max-sixty/worktrunk?style=for-the-badge&logo=github)](https://github.com/max-sixty/worktrunk/stargazers)

> **January 2026**: Worktrunk was [released](https://x.com/max_sixty/status/2006077845391724739?s=20) over the holidays, and lots of folks seem to be using it. It's built with love (there's no slop!). If social proof is helpful: I also created [PRQL](https://github.com/PRQL/prql) (10k stars) and am a maintainer of [Xarray](https://github.com/pydata/xarray) (4k stars), [Insta](https://github.com/mitsuhiko/insta), & [Numbagg](https://github.com/numbagg/numbagg). Please let me know any frictions at all; I'm intensely focused on Worktrunk's excellence, and the biggest gap is how others experience using it.

Worktrunk is a CLI for git worktree management, designed for running AI agents in parallel.

Worktrunk's three core commands make worktrees as easy as branches. Plus, Worktrunk has a bunch of quality-of-life features to simplify working with many parallel changes, including hooks to automate local workflows.

Scaling agents becomes trivial. A quick demo:

![Worktrunk Demo](https://cdn.jsdelivr.net/gh/max-sixty/worktrunk-assets@main/assets/docs/light/wt-core.gif)

> ### 📚 Full documentation at [worktrunk.dev](https://worktrunk.dev) 📚

## Context: git worktrees

AI agents like Claude Code and Codex can handle longer tasks without
supervision, such that it's possible to manage 5-10+ in parallel. Git's native
worktree feature give each agent its own working directory, so they don't step
on each other's changes.

But the git worktree UX is clunky. Even a task as small as starting a new
worktree requires typing the branch name three times: `git worktree add -b feat
../repo.feat`, then `cd ../repo.feat`.

## Worktrunk makes git worktrees as easy as branches

Worktrees are addressed by branch name; paths are computed from a configurable template.

> Start with the core commands

**Core commands:**

- Switch worktrees: `wt switch <branch>`
- Create worktree: `wt switch -c <branch>`
- List worktrees: `wt list`
- Remove worktree: `wt remove`

## Install

**Homebrew (macOS & Linux):**

```bash
brew install max-sixty/worktrunk/wt && wt config shell install
```

Shell integration allows commands to change directories.

**Cargo:**

```bash
cargo install worktrunk && wt config shell install
```

## Next steps

- Learn the core commands: `wt switch`, `wt list`, `wt merge`, `wt remove`
- Run `wt --help` or `wt <command> --help` for quick CLI reference

<!-- End vendored README -->
