# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

An Arch/AUR package (`tuned-cachyos-profiles-git`) that installs custom TuneD profiles for CachyOS. The profiles live under `etc/tuned/profiles/` and are deployed to `/etc/tuned/profiles/` on the target system.

## Build & install

```bash
makepkg -si          # build package and install via pacman
makepkg --printsrcinfo > .SRCINFO   # regenerate .SRCINFO for AUR submission
```

Manual apply without packaging (for quick testing):
```bash
sudo cp -r etc/tuned/profiles/* /etc/tuned/profiles/
sudo tuned-adm profile <profile-name>
tuned-adm active
```

Verify CPU settings took effect:
```bash
cat /sys/devices/system/cpu/cpufreq/boost
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort -u
```

## Profile architecture

Each profile is a single `tuned.conf` that `include=`s an upstream TuneD base profile, then overrides specific sections (`[cpu]`, `[vm]`, `[sysctl]`).

| Profile | Use case |
|---|---|
| `balanced-cachyos` | General desktop/laptop, good efficiency |
| `battery-balanced-cachyos` | Laptop on battery, responsive |
| `laptop-ac-balanced-cachyos` | Laptop plugged in, balanced |
| `laptop-ac-powersaver-cachyos` | Plugged in but thermal/fan limited |
| `laptop-battery-powersaver-cachyos` | Maximum battery life |
| `throughput-performance-cachyos` | Desktop/gaming, max clocks |

## Scripts

`scripts/pre-apply.sh` and `scripts/post-apply.sh` at the repo root are fanned out by `PKGBUILD` to **every** profile's `scripts/` subdirectory during packaging. Per-profile scripts go under `etc/tuned/profiles/<name>/scripts/` instead.

## Key design decisions

- **`turbo=1` is intentional even in power-saving profiles.** On AMD Ryzen APUs, disabling turbo causes hangs and crashes when the iGPU and CPU compete for the shared power budget. The "race to sleep" principle means short bursts are more efficient than throttled-and-hung states. See `CHANGELOG-stability-fixes.md` for the full rationale.
- **`amd_pstate=guided` is assumed** — `max_perf_pct`/`min_perf_pct` are the primary power controls, not hard governor locks.
- All `tuned.conf` files are in pacman's `backup=()` list so user edits survive package upgrades as `.pacnew` files.

## .gitignore quirk

`.gitignore` contains `/etc/` (which would normally exclude the `etc/` directory), but the profile files are already tracked. Do not remove them from tracking — they are the deliverable of this package.
