package: POWHEG
version: "%(tag_basename)s"
tag: "r3964-alice2"
source: https://github.com/alisw/POWHEG
requires:
  - fastjet
  - "GCC-Toolchain:(?!osx|slc5)"
  - lhapdf
  - lhapdf-pdfsets
  - looptools
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./
basedir=`pwd`

install -d ${INSTALLROOT}/bin

export LIBRARY_PATH="$LD_LIBRARY_PATH"

# Executables for each porcess separate
PROCESSES="${FASTJET_REVISION:+dijet }hvq W Z directphoton"
for proc in ${PROCESSES}; do
    mkdir ${proc}/{obj,obj-gfortran}
    ln -s $basedir/include ${proc}/
    make -C ${proc}
    install ${proc}/pwhg_main ${INSTALLROOT}/bin/pwhg_main_${proc}
done

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set POWHEG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv POWHEG_ROOT \$POWHEG_ROOT
setenv Powheg_INSTALL_PATH \$::env(POWHEG_ROOT)/lib/Powheg
prepend-path PATH \$POWHEG_ROOT/bin
prepend-path LD_LIBRARY_PATH \$POWHEG_ROOT/lib/Powheg
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
