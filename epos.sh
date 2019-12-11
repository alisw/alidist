package: EPOS
version: "%(tag_basename)s"
tag: "v3.111-alice1"
source: https://gitlab.cern.ch/ALICEPrivateExternals/epos.git
requires:
  - ROOT
  - fastjet
env:
  EPOVSN: "${EPOS_VERSION/./}"
  EPO: "${EPOS_ROOT}/epos/"
---
#!/bin/bash -ex

export EPOVSN=${PKGVERSION/./}

# The following two variables *must* have a trailing slash! EPOS installation
# will make a mess otherwise.
export EPO=$PWD/
export OBJ=$EPO/Unu/Lib/

rsync -a --exclude='**/.git' --delete ${SOURCEDIR}/ .
mkdir $OBJ

export LDFLAGS="-Wl,--no-as-needed -L${MPFR_ROOT}/lib -L${GMP_ROOT}/lib -L${CGAL_ROOT}/lib"
export LIBRARY_PATH="$LD_LIBRARY_PATH"
make LFLAGS="$LDFLAGS"

# "Install"
INST_SUBROOT=$INSTALLROOT/epos
mkdir -p $INST_SUBROOT \
         $INSTALLROOT/bin
rsync -a \
      --exclude='**/bin' \
      --exclude='**/.git' \
      --exclude=*.f \
      --exclude=*.o \
      --exclude=*.h \
      --exclude=*.c \
      --exclude=*.cpp \
      --exclude=Makefile \
      ./ $INST_SUBROOT/
rsync -a bin/ $INSTALLROOT/bin/
find $INSTALLROOT -type d -empty -exec rmdir '{}' \; > /dev/null 2>&1 || true
[ -d "$INST_SUBROOT/Unu/Lib/epos$EPOVSN" ]

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION
# Our environment
set EPOS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(EPOS_ROOT)/bin
setenv EPOVSN ${EPOVSN}
# Final slash is required by EPOS, please leave it be
set EPO $::env(EPOS_ROOT)/epos/
EoF
