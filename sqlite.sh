package: sqlite
version: "%(tag_basename)s"
tag: "v3.15.0"
source: https://github.com/alisw/sqlite
prefer_system: (?!slc5)
prefer_system_check: |
  printf '#include <sqlite3.h>\nint main(){}\n' | cc -xc - -lsqlite3 -o /dev/null;
  if [ $? -ne 0 ]; then printf "SQLite not found.\n * On RHEL-compatible systems you probably need: sqlite sqlite-devel\n * On Ubuntu-compatible systems you probably need: libsqlite3-0 libsqlite3-dev\n"; exit 1; fi
build_requires:
  - system-curl
  - "autotools:(slc6|slc7)"
  - alibuild-recipe-tools
---
#!/bin/bash -ex
rsync -av $SOURCEDIR/ ./
autoreconf -ivf
./configure --disable-tcl --disable-readline --disable-static --prefix=$INSTALLROOT
make
make install
rm -f $INSTALLROOT/lib/*.la
rm -rf $INSTALLROOT/share

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --root-env > "$MODULEDIR/$PKGNAME"
