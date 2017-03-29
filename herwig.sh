package: Herwig
version: "%(tag_basename)s%(defaults_upper)s"
source: https://github.com/alisw/herwig
tag: "alice/v7.0.4"
requires:
  - GSL
  - ThePEG
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf
export LDFLAGS="-L$LHAPDF_ROOT/lib"
./configure                            \
    --prefix="$INSTALLROOT"            \
    --with-thepeg="${THEPEG_ROOT}"     \
    --with-gsl="${GSL_ROOT}"

make ${JOBS:+-j ${JOBS}}
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
module load BASE/1.0 ThePEG/$THEPEG_VERSION-$THEPEG_REVISION
# Our environment
setenv HERWIG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv HERWIG_INSTALL_PATH \$::env(HERWIG_ROOT)/lib/Herwig
prepend-path PATH \$::env(HERWIG_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(HERWIG_ROOT)/lib/Herwig
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(HERWIG_ROOT)/lib/Herwig")
EoF
