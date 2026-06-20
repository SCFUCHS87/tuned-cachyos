# Repository Guidelines

## Project Structure & Module Organization

This repository packages CachyOS-specific TuneD profiles for Arch/AUR as `tuned-cachyos-profiles-git`. The package entry points are `PKGBUILD`, `.SRCINFO`, and `tuned-cachyos-profiles-git.install`. Profile sources live in `etc/tuned/profiles/<profile-name>/tuned.conf` and are installed to `/etc/tuned/profiles/`. Root-level scripts in `scripts/` are fanned out by `PKGBUILD` to every profile during packaging.

PPD mapping lives in `/etc/tuned/ppd.conf`, which is owned by the `tuned-ppd` package. This package does not ship that file as a payload — instead, `tuned-cachyos-profiles-git.install` writes the CachyOS mapping into it on install and refreshes it on every upgrade. The file is stamped with `# managed by tuned-cachyos-profiles-git` so the install script can distinguish it from a foreign config (foreign files get backed up to `ppd.conf.tuned-cachyos.bak` first). On removal the backup is restored and deleted; if none exists, ppd.conf is removed.

## Build, Test, and Development Commands

- `makepkg -si`: build the Arch package and install it locally with pacman.
- `makepkg --printsrcinfo > .SRCINFO`: regenerate AUR metadata after changing `PKGBUILD`.
- `tuned-adm active`: verify the active TuneD profile on a target system.
- `tuned-adm verify`: compare live settings with the active profile.
- `cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | sort -u`: confirm AMD EPP settings took effect.

For quick manual testing, copy profile files to `/etc/tuned/profiles/` and apply one with `sudo tuned-adm profile <profile-name>`.

## Coding Style & Naming Conventions

Use shell-compatible style in scripts: two-space indentation inside functions and conditionals, quoted variables, and explicit paths. Keep profile names lowercase and hyphenated, ending in `-cachyos` where they are package-specific. TuneD configuration should remain simple INI-style sections such as `[cpu]`, `[vm]`, and `[sysctl]`. Use `boost=1`, not `turbo=1`, for TuneD CPU boost control.

## Testing Guidelines

There is no automated test suite. Validate by building with `makepkg -si`, switching profiles with `tuned-adm`, and checking CPU governor, boost, EPP, and relevant sysctl values. For packaging changes, inspect generated package contents before release and refresh `.SRCINFO`.

The package does not own `/etc/tuned/ppd.conf` as a pacman file — `tuned-ppd` owns it. The install script manages it instead. When testing install/upgrade/remove behavior, verify that: ppd.conf is written with the sentinel comment on install; ppd.conf is refreshed on upgrade; a foreign ppd.conf is backed up before being overwritten; the backup is restored and deleted on remove.

## Commit & Pull Request Guidelines

Recent commits use short imperative summaries, for example `Bump pkgver to r15.9ebe2fb, regenerate .SRCINFO`. Keep commits focused: profile behavior, packaging metadata, scripts, or docs. Pull requests should explain the affected profile or packaging path, include validation commands run, and mention any hardware assumptions such as AMD `amd-pstate-epp`.

## Agent-Specific Instructions

Keep `AGENTS.md` and `CLAUDE.md` aligned when workflow, architecture, or validation guidance changes. Do not remove tracked `etc/` profile files because `.gitignore` contains `/etc/`; those tracked files are the package payload.
