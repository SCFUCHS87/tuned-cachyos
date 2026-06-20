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

Profiles are wired to KDE PowerDevil via `/etc/tuned/ppd.conf`, which maps PPD states to TuneD profiles separately for AC and battery. `tuned-ppd` owns that file, so this package does not ship it as a payload file. Instead, `tuned-cachyos-profiles-git.install` writes the mapping on install. The file is stamped with `# managed by tuned-cachyos-profiles-git` so the install script can distinguish it from a foreign config; foreign files are backed up once to `/etc/tuned/ppd.conf.tuned-cachyos.bak` before being replaced on install. On upgrade, managed files are preserved and non-managed files are left untouched. On removal, backups are restored only when the current file is missing or managed; unrelated current files are preserved.

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

## What to update when you change things

**Changing a profile's tuning values (`tuned.conf`):**
- Update the profile file under `etc/tuned/profiles/<name>/tuned.conf`
- Update the profile details table in `README.md` if EPP, governor, or swappiness changed
- Update the profile table in `CLAUDE.md` if the role or EPP changed

**Adding or removing a profile:**
- Add/remove the profile directory under `etc/tuned/profiles/`
- Add/remove it from `backup=()` in `PKGBUILD`
- Regenerate `.SRCINFO`: `makepkg --printsrcinfo > .SRCINFO`
- Update the ppd.conf mappings in `tuned-cachyos-profiles-git.install`
- Update the PPD mapping tables in `README.md` and `CLAUDE.md`
- Update `AGENTS.md` if the structure description changes

**Changing the PPD mappings (which profile maps to which PPD state):**
- Update the `cat > "$ppd_conf"` block inside `_configure_ppd()` in `tuned-cachyos-profiles-git.install`
- Update the PPD mapping tables in `README.md` and `CLAUDE.md`

**Changing `PKGBUILD` (deps, options, package logic):**
- Always regenerate `.SRCINFO` afterwards: `makepkg --printsrcinfo > .SRCINFO`
- Commit both files together

**Changing `scripts/pci-pm.sh`:**
- Update the Scripts section in `CLAUDE.md` if behavior changes
- Copy to live profiles manually for testing, or rebuild with `makepkg -si`

**Changing the install script (`tuned-cachyos-profiles-git.install`):**
- Update the ppd.conf lifecycle description in `CLAUDE.md` and `README.md`
- Update the Testing Guidelines in `AGENTS.md`

## Key design decisions

- **`boost=1` is intentional even in power-saving profiles.** On AMD Ryzen APUs, disabling turbo causes hangs and crashes when the iGPU and CPU compete for the shared power budget. The "race to sleep" principle means short bursts are more efficient than throttled-and-hung states. Note: the TuneD CPU plugin option is `boost=` (not `turbo=` — that is silently ignored).
- **Driver is `amd-pstate-epp`** (confirmed on Ryzen 5 7535HS). Only `powersave` and `performance` governors are available — `schedutil` is not valid and will warn/no-op. Use `governor=powersave` for all efficiency profiles, `governor=performance` only for `throughput-performance-cachyos`. The primary power control is `energy_performance_preference=` (not `energy_perf_bias=`, which is Intel-only). `max_perf_pct`/`min_perf_pct` still work as hard frequency bounds on top of EPP.
- All `tuned.conf` files are in pacman's `backup=()` list so user edits survive package upgrades as `.pacnew` files.

## .gitignore quirk

`.gitignore` contains `/etc/` (which would normally exclude the `etc/` directory), but the profile files are already tracked. Do not remove them from tracking — they are the deliverable of this package.
