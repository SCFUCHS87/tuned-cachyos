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

# Configure ppd.conf (must be run from the repo root):
sudo sh -c '. ./tuned-cachyos-profiles-git.install; _configure_ppd'

sudo tuned-adm profile <profile-name>
tuned-adm active
```

Verify CPU settings took effect:
```bash
cat /sys/devices/system/cpu/cpufreq/boost
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort -u
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | sort -u
```

## Profile architecture

Each profile is a single `tuned.conf` that `include=`s an upstream TuneD base profile, then overrides specific sections (`[cpu]`, `[vm]`, `[sysctl]`).

Profiles are wired to KDE PowerDevil via `/etc/tuned/ppd.conf`, which maps PPD states to TuneD profiles separately for AC and battery. `tuned-ppd` owns that file, so this package does not ship it as a payload file. Instead, `tuned-cachyos-profiles-git.install` writes the mapping on install and refreshes it on every upgrade. The file is stamped with `# managed by tuned-cachyos-profiles-git` so the install script can distinguish it from a foreign config — foreign files are backed up to `/etc/tuned/ppd.conf.tuned-cachyos.bak` before being overwritten. On removal the backup is restored (and the backup file deleted); if no backup exists, ppd.conf is removed and tuned-ppd will recreate a default on next start.

| PPD state | On AC | On battery |
|---|---|---|
| `performance` | `throughput-performance-cachyos` | `balanced-cachyos` |
| `balanced` | `laptop-ac-balanced-cachyos` | `battery-balanced-cachyos` |
| `power-saver` | `laptop-ac-powersaver-cachyos` | `laptop-battery-powersaver-cachyos` |

KDE PowerDevil defaults: AC → `performance`, Battery → `power-saver`.

| Profile | Role | EPP |
|---|---|---|
| `throughput-performance-cachyos` | Gaming/compute, no limits | `performance` |
| `laptop-ac-balanced-cachyos` | AC balanced, snappy + efficient | `balance_performance` |
| `laptop-ac-powersaver-cachyos` | AC powersaver, cool & quiet | `balance_power` |
| `balanced-cachyos` | Performance on battery | `balance_performance` |
| `battery-balanced-cachyos` | Balanced on battery | `balance_power` |
| `laptop-battery-powersaver-cachyos` | Max battery life | `power` |

## Scripts

`scripts/` at the repo root is fanned out by `PKGBUILD` to **every** profile's `scripts/` subdirectory during packaging. Currently contains `pci-pm.sh`, which sets PCI/USB runtime PM on profile start and restores `on` on stop. Profiles reference it via `${i:PROFILE_DIR}/scripts/pci-pm.sh`. The `[audio] timeout=` plugin in each `tuned.conf` handles `snd_hda_intel` separately — pci-pm.sh does not touch it.

For manual installs (no `makepkg`), copy `scripts/pci-pm.sh` to each profile's `scripts/` dir by hand:
```bash
for p in balanced-cachyos battery-balanced-cachyos laptop-ac-balanced-cachyos laptop-ac-powersaver-cachyos laptop-battery-powersaver-cachyos; do
  sudo install -Dm755 scripts/pci-pm.sh /etc/tuned/profiles/$p/scripts/pci-pm.sh
done
```

Per-profile-specific scripts go under `etc/tuned/profiles/<name>/scripts/` instead of the root `scripts/`.

## Key design decisions

- **`boost=1` is intentional even in power-saving profiles.** On AMD Ryzen APUs, disabling turbo causes hangs and crashes when the iGPU and CPU compete for the shared power budget. The "race to sleep" principle means short bursts are more efficient than throttled-and-hung states. Note: the TuneD CPU plugin option is `boost=` (not `turbo=` — that is silently ignored).
- **Driver is `amd-pstate-epp`** (confirmed on Ryzen 5 7535HS). Only `powersave` and `performance` governors are available — `schedutil` is not valid and will warn/no-op. Use `governor=powersave` for all efficiency profiles, `governor=performance` only for `throughput-performance-cachyos`. The primary power control is `energy_performance_preference=` (not `energy_perf_bias=`, which is Intel-only). `max_perf_pct`/`min_perf_pct` still work as hard frequency bounds on top of EPP.
- All `tuned.conf` files are in pacman's `backup=()` list so user edits survive package upgrades as `.pacnew` files.

## .gitignore quirk

`.gitignore` contains `/etc/` (which would normally exclude the `etc/` directory), but the profile files are already tracked. Do not remove them from tracking — they are the deliverable of this package.
