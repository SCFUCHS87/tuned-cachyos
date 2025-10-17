# Maintainer: Steven Fuchs <stevencfuchs@icloud.com>
pkgname=tuned-cachyos-profiles-git
pkgver=0.1.r0.g0000000
pkgrel=1
pkgdesc="CachyOS-flavored TuneD profiles installed under /etc/tuned/profiles/"
arch=('any')
url="https://github.com/SCFUCHS87/tuned-cachyos"
license=('MIT')
depends=('tuned')
makedepends=('git')
source=("git+$url")
sha256sums=('SKIP')
install=$pkgname.install

# NOTE: Once your profile names are stable, explicitly list them in backup=()
# so pacman preserves /etc changes.
# Example:
# backup=(
#   'etc/tuned/profiles/balanced-cachyos/tuned.conf'
#   'etc/tuned/profiles/throughput-performance-cachyos/tuned.conf'
#   'etc/tuned/profiles/powersave-cachyos/tuned.conf'
# )

pkgver() {
  cd "$srcdir/tuned-cachyos"
  git describe --tags --long --always --dirty 2>/dev/null | sed 's/^v//; s/-/./g'
}

package() {
  cd "$srcdir/tuned-cachyos"

  # Your repo layout: etc/tuned/profiles/<profile>[/files...]
  local src_profiles="$PWD/etc/tuned/profiles"
  local dest_root="$pkgdir/etc/tuned/profiles"

  install -d "$dest_root"

  # Copy every profile dir that contains tuned.conf
  find "$src_profiles" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' d; do
    [ -f "$d/tuned.conf" ] || continue
    prof="$(basename "$d")"
    install -d "$dest_root/$prof"

    # tuned.conf
    install -m644 "$d/tuned.conf" "$dest_root/$prof/"

    # Any other top-level files (ini, rules, service, sh, etc.)
    find "$d" -maxdepth 1 -type f ! -name 'tuned.conf' -print0 | while IFS= read -r -d '' f; do
      bn="$(basename "$f")"
      if [ -x "$f" ]; then
        install -Dm755 "$f" "$dest_root/$prof/$bn"
      else
        install -Dm644 "$f" "$dest_root/$prof/$bn"
      fi
    done

    # scripts/ subtree (preserve exec bits)
    if [ -d "$d/scripts" ]; then
      find "$d/scripts" -type f -print0 | while IFS= read -r -d '' sf; do
        rel="scripts/${sf##*/}"
        if [ -x "$sf" ]; then
          install -Dm755 "$sf" "$dest_root/$prof/$rel"
        else
          install -Dm644 "$sf" "$dest_root/$prof/$rel"
        fi
      done
    fi
  done

  # Docs
  install -d "$pkgdir/usr/share/doc/$pkgname"
  [ -f README.md ] && install -m644 README.md "$pkgdir/usr/share/doc/$pkgname/"

  # License
  install -d "$pkgdir/usr/share/licenses/$pkgname"
  [ -f LICENSE ] && install -m644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/"
}
