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
options=('!strip')  # all text/scripts; nothing to strip

# Preserve user edits to tuned.conf under /etc (pacman shows .pacnew on updates)
backup=(
  'etc/tuned/profiles/balanced-cachyos/tuned.conf'
  'etc/tuned/profiles/battery-balanced-cachyos/tuned.conf'
  'etc/tuned/profiles/laptop-ac-balanced-cachyos/tuned.conf'
  'etc/tuned/profiles/laptop-ac-powersaver-cachyos/tuned.conf'
  'etc/tuned/profiles/laptop-battery-powersaver-cachyos/tuned.conf'
  'etc/tuned/profiles/throughput-performance-cachyos/tuned.conf'
)

pkgver() {
  cd "$srcdir/tuned-cachyos"
  # vX.Y.Z-123-gabcdef -> X.Y.Z.123.gabcdef ; falls back to commit-ish if no tags
  git describe --tags --long --always --dirty 2>/dev/null | sed 's/^v//; s/-/./g'
}

_copy_file() {
  local src="$1" dest="$2"
  if [[ -x "$src" ]]; then
    install -Dm755 "$src" "$dest"
  else
    install -Dm644 "$src" "$dest"
  fi
}

package() {
  cd "$srcdir/tuned-cachyos"

  local src_profiles="$PWD/etc/tuned/profiles"
  local dest_root="$pkgdir/etc/tuned/profiles"

  install -d "$dest_root"

  # For each profile dir, copy tuned.conf + any top-level files, plus scripts/
  find "$src_profiles" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' d; do
    prof="$(basename "$d")"
    install -d "$dest_root/$prof"

    # tuned.conf (optional but expected by tuned)
    if [[ -f "$d/tuned.conf" ]]; then
      install -m644 "$d/tuned.conf" "$dest_root/$prof/"
    fi

    # Extra top-level files (ini, rules, service, sh, md, etc.)
    find "$d" -maxdepth 1 -type f ! -name 'tuned.conf' -print0 | while IFS= read -r -d '' f; do
      _copy_file "$f" "$dest_root/$prof/$(basename "$f")"
    done

    # Per-profile scripts/
    if [[ -d "$d/scripts" ]]; then
      while IFS= read -r -d '' sf; do
        _copy_file "$sf" "$dest_root/$prof/scripts/${sf##*/}"
      done < <(find "$d/scripts" -type f -print0)
    fi

    # Repo-root scripts/ (fan out to every profile)
    if [[ -d "$PWD/scripts" ]]; then
      while IFS= read -r -d '' sf; do
        _copy_file "$sf" "$dest_root/$prof/scripts/${sf##*/}"
      done < <(find "$PWD/scripts" -type f -print0)
    fi
  done

  # Docs
  install -d "$pkgdir/usr/share/doc/$pkgname"
  [[ -f README ]] && install -m644 README "$pkgdir/usr/share/doc/$pkgname/"
  [[ -f README.md ]] && install -m644 README.md "$pkgdir/usr/share/doc/$pkgname/"

  # License
  install -d "$pkgdir/usr/share/licenses/$pkgname"
  [[ -f LICENSE ]] && install -m644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/"
}
