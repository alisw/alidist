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
export OBJ=${EPO}Unu/Lib/
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

# wrapper script to set all recommended environment
cat > ${INSTALLROOT}/run_epos.sh <<EOF
#!/bin/bash

export FASTSYS=\${FASTSYS:-\$FASTJET}
export WORK=\${WORK:-\${EPO}Unu/}
export OBJ=\${OBJ:-\${WORK}Lib/}
export CHK=\${CHK:-\${WORK}}
export OPT=\${OPT:-\${WORK}}
export HTO=\${HTO:-\${WORK}}
export DTA=\${DTA:-\${WORK}}
export EOS=\${EOS:-\${WORK}}
export SPO=\${SPO:-\${WORK}}

\${EPOS_ROOT}/\$*
EOF
chmod a+x ${INSTALLROOT}/run_epos.sh

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
EoF
