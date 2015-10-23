package: EPOS
version: "%(tag_basename)s"
tag: alice/v3.111
source: ssh://git@gitlab.cern.ch:7999/ALICEPrivateExternals/epos.git
requires:
  - ROOT
  - fastjet
---
#!/bin/bash -ex

export EPOVSN=${PKGVERSION/./}
export EPO=$PWD/
export FASTSYS=$FASTJET
export WORK=${EPO}Unu/
export OBJ=${WORK}Lib/
export CHK=${WORK}
export OPT=${WORK}
export HTO=${WORK}
export DTA=${WORK}
export EOS=${WORK}
export SPO=${WORK}
export LIBRARY_PATH=$LIBRARY_PATH:$LD_LIBRARY_PATH

# need to build in-source
rsync -a --delete ${SOURCEDIR}/ .

# prepare and compile
mkdir $OBJ
make

# stupid installation
rsync -a \
      --exclude=.git \
      --exclude=*.f \
      --exclude=*.o \
      --exclude=*.h \
      --exclude=*.c \
      --exclude=*.cpp \
      ./ $INSTALLROOT/

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
setenv ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(${PKGNAME}_ROOT)/

setenv EPOVSN ${PKGVERSION/./}
setenv EPO   $::env(${PKGNAME}_ROOT)/
setenv FASTSYS  $::env(FASTJET_ROOT)
setenv WORK $::env(EPO)Unu/
setenv OBJ   $::env(WORK)Lib/
setenv CHK   $::env(WORK)
setenv OPT   $::env(WORK)
setenv HTO   $::env(WORK)
setenv DTA   $::env(WORK)
setenv EOS   $::env(WORK)
setenv SPO   $::env(WORK)
EoF
