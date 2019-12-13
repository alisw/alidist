package: Herwig
version: "%(tag_basename)s"
tag: "v7.1.2-alice1"
source: https://github.com/alisw/herwig
requires:
  - GMP
  - GSL
  - ThePEG
  - lhapdf-pdfsets
build_requires:
  - autotools
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./


export LHAPDF_DATA_PATH="$LHAPDF_ROOT/share/LHAPDF:$LHAPDF_PDFSETS_ROOT/share/LHAPDF"

[[ -e .missing_timestamps ]] && ./missing-timestamps.sh --apply || autoreconf -ivf
[[ $ALIEN_RUNTIME_VERSION ]] && LDZLIB="-L$ALIEN_RUNTIME_ROOT/lib" || { [[ $ZLIB_VERSION ]] && LDZLIB="-L$ZLIB_ROOT/lib" || LDZLIB= ; }
export LDFLAGS="-L$LHAPDF_ROOT/lib -L$CGAL_ROOT/lib $LDZLIB"
./configure                        \
    --prefix="$INSTALLROOT"        \
    --with-thepeg="${THEPEG_ROOT}" \
    --with-gsl="${GSL_ROOT}"

make ${JOBS:+-j $JOBS}
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
module load BASE/1.0 ThePEG/$THEPEG_VERSION-$THEPEG_REVISION lhapdf-pdfsets/$LHAPDF_PDFSETS_VERSION-$LHAPDF_PDFSETS_REVISION
# Our environment
set HERWIG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv HERWIG_ROOT \$HERWIG_ROOT
setenv HERWIG_INSTALL_PATH \$::env(HERWIG_ROOT)/lib/Herwig
prepend-path PATH \$HERWIG_ROOT/bin
prepend-path LD_LIBRARY_PATH \$HERWIG_ROOT/lib/Herwig
EoF
