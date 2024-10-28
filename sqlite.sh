package: sqlite
version: "%(tag_basename)s"
tag: "v3.15.0"
source: https://github.com/alisw/sqlite
prefer_system: (?!slc5)
prefer_system_check: |
  printf '#include <sqlite3.h>\nint main(){}\n' | cc -xc - -lsqlite3 -o /dev/null;
  if [ $? -ne 0 ]; then printf "SQLite not found.\n * On RHEL-compatible systems you probably need: sqlite sqlite-devel\n * On Ubuntu-compatible systems you probably need: libsqlite3-0 libsqlite3-dev\n"; exit 1; fi
build_requires:
  - curl
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
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
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
set SQLITE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv SQLITE_ROOT \$SQLITE_ROOT
prepend-path PATH \$SQLITE_ROOT/bin
prepend-path LD_LIBRARY_PATH \$SQLITE_ROOT/lib
EoF
