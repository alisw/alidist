package: SHERPA
version: "%(tag_basename)s"
source: https://github.com/alisw/SHERPA
tag: "alice/v2.1.1"
build_requires:
  - autotools
  - GCC-Toolchain
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf
./configure --prefix=$INSTALLROOT \
            --with-sqlite3=install

make ${JOBS+-j $JOBS}
make install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv SHERPA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv SHERPA_INSTALL_PATH \$::env(SHERPA_ROOT)/lib/SHERPA
prepend-path PATH \$::env(SHERPA_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(SHERPA_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(SHERPA_ROOT)/lib")
prepend-path LD_LIBRARY_PATH \$::env(SHERPA_ROOT)/lib/SHERPA-MC
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(SHERPA_ROOT)/lib/SHERPA-MC")
EoF
