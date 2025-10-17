# tuned-cachyos-profiles

CachyOS-flavored **TuneD** profiles for performance-tuned Linux systems.

These profiles install under `/etc/tuned/profiles/<profile>/` and integrate seamlessly with the `tuned` daemon.

---

## 🧩 Overview

This package provides several optimized TuneD profiles designed for CachyOS and Arch-based systems:

- **balanced-cachyos** — general-purpose performance with good power efficiency  
- **battery-balanced-cachyos** — tuned for laptops on battery power  
- **laptop-ac-balanced-cachyos** — tuned for laptops on AC power  
- **laptop-ac-powersaver-cachyos** — conservative AC profile for thermal or fan-limited systems  
- **laptop-battery-powersaver-cachyos** — maximum battery life  
- **throughput-performance-cachyos** — maximum throughput for desktop or workstation use

Each profile may contain custom sysctl, CPU governor, and I/O tuning options.

---

## ⚙️ Installation

### From Source (local build)

```bash
git clone https://github.com/SCFUCHS87/tuned-cachyos.git
cd tuned-cachyos
makepkg -si
