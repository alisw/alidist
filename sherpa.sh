package: SHERPA
version: "%(tag_basename)s"
tag: "v2.2.4-alice1"
source: https://github.com/alisw/SHERPA
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - curl
  - autotools
  - HepMC
  - lhapdf5
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

# SHERPA's configure uses wget which might not be there
mkdir -p fakewget && [[ -d fakewget ]]
printf '#!/bin/bash\nexec curl -fO $1' > fakewget/wget && chmod +x fakewget/wget

PATH=$PATH:fakewget ./configure --prefix=$INSTALLROOT        \
                                --with-sqlite3=install       \
                                --enable-hepmc2=$HEPMC_ROOT  \
                                --enable-lhapdf=$LHAPDF5_ROOT

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv SHERPA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv SHERPA_INSTALL_PATH \$::env(SHERPA_ROOT)/lib/SHERPA
prepend-path PATH \$SHERPA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$SHERPA_ROOT/lib
prepend-path LD_LIBRARY_PATH \$SHERPA_ROOT/lib/SHERPA-MC
EoF
