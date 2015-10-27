package: EPOS
version: "%(tag_basename)s"
tag: alice/v3.111
source: https://gitlab.cern.ch/ALICEPrivateExternals/epos.git
requires:
  - ROOT
  - fastjet
---
#!/bin/bash -ex

export EPOVSN=${PKGVERSION/./}

# Please note that EPOS *requires* the EPO variable to have a trailing slash!
# It will not compile otherwise!
export EPO=$PWD/
export OBJ=$EPO/Unu/Lib

rsync -a --exclude='**/.git' --delete ${SOURCEDIR}/ .
mkdir $OBJ

export LDFLAGS="-Wl,--no-as-needed -L${MPFR_ROOT}/lib -L${GMP_ROOT}/lib -L${CGAL_ROOT}/lib"
export LIBRARY_PATH="$LD_LIBRARY_PATH"
make ${JOBS:+-j$JOBS} LFLAGS="$LDFLAGS"

# "Install"
mkdir -p $INSTALLROOT/share/epos \
         $INSTALLROOT/bin
rsync -a \
      --exclude=.git \
      --exclude=*.f \
      --exclude=*.o \
      --exclude=*.h \
      --exclude=*.c \
      --exclude=*.cpp \
      --exclude=Makefile \
      --exclude=*.md \
      --exclude=epos-wrap \
      ./ $INSTALLROOT/share/epos/
cp epos-wrap $INSTALLROOT/bin
chmod a=rx $INSTALLROOT/bin/epos-wrap
find $INSTALLROOT -type d -empty -exec rmdir '{}' \; || true

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
setenv EPOS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(EPOS_ROOT)/bin
setenv EPOVSN ${EPOVSN}
# Final slash is required by EPOS, please leave it there
setenv EPO $::env(EPOS_ROOT)/share/epos/
EoF
