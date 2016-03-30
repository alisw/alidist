package: POWHEG
version: "%(tag_basename)s"
source: https://github.com/qgp/POWHEG-BOX-V2
tag: "master"
requires:
  - fastjet
  - "GCC-Toolchain:(?!osx|slc5)"
  - lhapdf5
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

install -d ${INSTALLROOT}/bin

export LIBRARY_PATH="$LD_LIBRARY_PATH"

PROCESSES="dijet hvq W Z"
for proc in ${PROCESSES}; do
    mkdir ${proc}/{obj,obj-gfortran}
    make -C ${proc}
    install ${proc}/pwhg_main ${INSTALLROOT}/bin/pwhg_main_${proc}
done

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
module load BASE/1.0 lhapdf5/$LHAPDF5_VERSION-$LHAPDF5_REVISION ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${FASTJET_VERSION:+fastjet/$FASTJET_VERSION-$FASTJET_REVISION}
# Our environment
setenv POWHEG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv Powheg_INSTALL_PATH \$::env(POWHEG_ROOT)/lib/Powheg
prepend-path PATH \$::env(POWHEG_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(POWHEG_ROOT)/lib/Powheg
EoF
