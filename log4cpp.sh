package: log4cpp
version: "%(tag_basename)s%(defaults_upper)s"
tag: REL_1_1_1_Nov_26_2013
source: https://github.com/PMunkes/log4cpp
requires:
  - GCC-Toolchain:(?!osx)
build_requires:
  - autotools
---
#!/bin/bash -ex
rsync -a $SOURCEDIR/ .
./autogen.sh
./configure          --prefix=$INSTALLROOT  \
		     --enable-shared        \
		     --enable-static        \
		      CXX="g++" CC="gcc" CXXFLAGS="$CFLAGS"
make ${JOBS+-j$JOBS}
make install

# Modulefile support
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
setenv LOG4_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(LOG4_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(LOG4_ROOT)/lib
EoF
