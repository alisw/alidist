package: sqlite
version: "v3.47.2"
tag: "version-3.47.2"
source: https://github.com/sqlite/sqlite
prefer_system: (?!slc5)
prefer_system_check: |
  printf '#include <sqlite3.h>\nint main(){}\n' | cc -xc - -lsqlite3 -o /dev/null;
  if [ $? -ne 0 ]; then printf "SQLite not found.\n * On RHEL-compatible systems you probably need: sqlite sqlite-devel\n * On Ubuntu-compatible systems you probably need: libsqlite3-0 libsqlite3-dev\n"; exit 1; fi
build_requires:
  - curl
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
---
#!/bin/bash -ex
rsync -av $SOURCEDIR/ ./
autoreconf -ivf
./configure --disable-tcl --disable-readline --disable-static --prefix=$INSTALLROOT
make ${JOBS:+-j $JOBS} 
make install
rm -f $INSTALLROOT/lib/*.la
rm -rf $INSTALLROOT/share

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin > "$MODULEFILE"
