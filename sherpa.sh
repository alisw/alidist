package: SHERPA
version: "%(tag_basename)s"
tag: "v2.2.8-alice1"
source: https://github.com/alisw/SHERPA
requires:
  - "GCC-Toolchain:(?!osx)"
  - Openloops
  - HepMC
  - lhapdf-pdfsets
  - fastjet
build_requires:
  - curl
  - autotools
  - cgal
  - GMP
---
#!/bin/bash -e

rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf

# SHERPA's configure uses wget which might not be there
mkdir -p fakewget && [[ -d fakewget ]]
printf '#!/bin/bash\nexec curl -fO $1' > fakewget/wget && chmod +x fakewget/wget

PATH=$PATH:fakewget 
export LDFLAGS="$LDFLAGS -L$CGAL_ROOT/lib  -L$GMP_ROOT/lib"
./configure --prefix=$INSTALLROOT        \
              --with-sqlite3=install       \
              --enable-hepmc2=$HEPMC_ROOT  \
              --enable-lhapdf=$LHAPDF_ROOT \
              --enable-openloops=$OPENLOOPS_ROOT \
        	    --enable-fastjet=$FASTJET_ROOT

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}               \\
                     ${LHAPDF_PDFSETS_REVISION:+lhapdf-pdfsets/$LHAPDF_PDFSETS_VERSION-$LHAPDF_PDFSETS_REVISION}           \\
                     ${FASTJET_REVISION:+fastjet/$FASTJET_VERSION-$FASTJET_REVISION}                                       \\
                     ${HEPMC_REVISION:+HepMC/$HEPMC_VERSION-$HEPMC_REVISION}                                               \\
                     ${OPENLOOPS_REVISION:+Openloops/$OPENLOOPS_VERSION-$OPENLOOPS_REVISION}
# Our environment
set SHERPA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv SHERPA_ROOT \$SHERPA_ROOT
setenv SHERPA_INSTALL_PATH \$::env(SHERPA_ROOT)/lib/SHERPA
setenv SHERPA_SHARE_PATH \$::env(SHERPA_ROOT)/share/SHERPA-MC
prepend-path PATH \$SHERPA_ROOT/bin
prepend-path LD_LIBRARY_PATH \$SHERPA_ROOT/lib
prepend-path LD_LIBRARY_PATH \$SHERPA_ROOT/lib/SHERPA-MC
EoF
