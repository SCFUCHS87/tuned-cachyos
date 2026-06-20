# tuned-cachyos-profiles-git

CachyOS-specific TuneD profiles for AMD laptops running `amd-pstate-epp`.

Most CachyOS users interact with Power Profiles Daemon (PPD) through KDE's power settings and stop there — three states, no scripting, no per-AC-vs-battery differentiation. This package replaces that with six TuneD profiles that cover every combination of AC/battery and PPD state, with tuning that is actually correct for AMD hardware.

---

## Why TuneD instead of PPD alone

PPD gives you three generic states. TuneD gives you:

- Separate profiles for AC and battery at each power level (six total vs three)
- `energy_performance_preference=` written correctly for `amd-pstate-epp` — most AMD configs out there still use `energy_perf_bias=`, which is an Intel MSR setting and does nothing on AMD
- `governor=powersave` explicitly set — `schedutil` is not available on `amd-pstate-epp` and silently no-ops
- PCI, USB, and audio runtime power management via a script that PPD never touches
- VM memory tuning (swappiness, dirty bytes, VFS cache pressure) scaled per power state
- Full KDE PowerDevil compatibility — KDE still controls everything through its power settings, TuneD just does the actual work underneath via `ppd.conf`

---

## Profile map

TuneD integrates with PPD via `/etc/tuned/ppd.conf`. KDE PowerDevil switches PPD states (performance / balanced / power-saver), and TuneD maps those to the right profile based on whether you are on AC or battery. The `tuned-ppd` package owns that file; this package configures the CachyOS mapping during install and backs up an existing non-CachyOS file as `/etc/tuned/ppd.conf.tuned-cachyos.bak`.

| PPD state    | On AC                          | On battery                         |
|---|---|---|
| performance  | `throughput-performance-cachyos` | `balanced-cachyos`               |
| balanced     | `laptop-ac-balanced-cachyos`   | `battery-balanced-cachyos`         |
| power-saver  | `laptop-ac-powersaver-cachyos` | `laptop-battery-powersaver-cachyos` |

KDE PowerDevil defaults to **performance on AC** and **power-saver on battery**, so in daily use you will mostly be hitting `throughput-performance-cachyos` when plugged in and `laptop-battery-powersaver-cachyos` on battery.

### Profile details

| Profile | EPP | Governor | Swappiness | Use case |
|---|---|---|---|---|
| `throughput-performance-cachyos` | `performance` | `performance` | 10 | Gaming, compute, no limits |
| `laptop-ac-balanced-cachyos` | `balance_performance` | `powersave` | 30 | AC balanced, snappy + efficient |
| `laptop-ac-powersaver-cachyos` | `balance_power` | `powersave` | 40 | AC powersaver, cool and quiet |
| `balanced-cachyos` | `balance_performance` | `powersave` | 30 | Performance on battery |
| `battery-balanced-cachyos` | `balance_power` | `powersave` | 50 | Balanced on battery |
| `laptop-battery-powersaver-cachyos` | `power` | `powersave` | 60 | Max battery life |

---

## AMD-specific design decisions

**`boost=1` in every profile, including powersavers.** On AMD Ryzen APUs the CPU and iGPU share a power budget. Disabling turbo causes the iGPU to grab the headroom the CPU gave up, which creates resource contention and can cause hangs. The race-to-sleep principle applies: a short turbo burst that finishes quickly uses less total energy than a throttled CPU that runs longer. Note: TuneD's CPU plugin uses `boost=` — the key `turbo=` is not recognized and is silently ignored.

**`energy_performance_preference=` not `energy_perf_bias=`.** The `energy_perf_bias` key in TuneD writes to an Intel MSR. On systems running `amd-pstate-epp` it is silently ignored. These profiles use the correct AMD key and set values that map cleanly to each profile's role.

**`governor=powersave` not `schedutil`.** On `amd-pstate-epp`, the available governors are `powersave` and `performance` only. `schedutil` does not exist in this context and generates warnings on every profile switch without taking effect. All efficiency profiles use `powersave` (which lets the EPP hint guide the hardware), and only `throughput-performance-cachyos` uses `performance`.

---

## RAM note (v1 / first release)

The VM tuning values in these profiles — `vm.swappiness`, `vm.vfs_cache_pressure` — were calibrated on a system with **64 GB of RAM**. On high-RAM systems, low swappiness is sensible because you rarely need to swap regardless. On systems with 8–16 GB, you may want to adjust these values upward, particularly for the battery profiles.

To override for your system, edit the `[sysctl]` section of whichever profile you use most. The files live at `/etc/tuned/profiles/<profile-name>/tuned.conf` and are marked as `backup=()` in the PKGBUILD, so pacman will present your edits as `.pacnew` files on upgrades rather than overwriting them.

A future release will make these values adaptive or provide documented per-RAM-size recommendations.

---

## Installation

### AUR

```bash
paru -S tuned-cachyos-profiles-git
# or
yay -S tuned-cachyos-profiles-git
```

### From source

```bash
git clone https://github.com/SCFUCHS87/tuned-cachyos.git
cd tuned-cachyos
makepkg -si
```

### Enable and start TuneD

```bash
sudo systemctl enable --now tuned
```

TuneD will pick up the active PPD state automatically via `ppd.conf`. No manual profile switching needed if you use KDE PowerDevil.

---

## Verifying settings took effect

```bash
tuned-adm active
cat /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference | sort -u
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor | sort -u
cat /sys/devices/system/cpu/cpufreq/boost
sysctl vm.swappiness
```

---

## Requirements

- `tuned` and `tuned-ppd` (dependencies, installed automatically)
- AMD CPU with `amd-pstate-epp` driver (`/sys/devices/system/cpu/amd_pstate/status` should read `active`)
- KDE / PowerDevil for automatic profile switching (optional — profiles work standalone too)

---

## License

MIT
