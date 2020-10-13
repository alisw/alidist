package: Herwig
version: "%(tag_basename)s"
tag: "v7.2.0"
source: https://github.com/alisw/herwig
requires:
  - GMP
  - GSL
  - ThePEG
  - lhapdf
  - lhapdf-pdfsets
  - Openloops
  - madgraph
build_requires:
  - autotools
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

export LHAPDF_DATA_PATH="$LHAPDF_ROOT/share/LHAPDF:$LHAPDF_PDFSETS_ROOT/share/LHAPDF"

[[ -e .missing_timestamps ]] && ./missing-timestamps.sh --apply || autoreconf -ivf
[[ $ALIEN_RUNTIME_VERSION ]] && LDZLIB="-L$ALIEN_RUNTIME_ROOT/lib" || { [[ $ZLIB_VERSION ]] && LDZLIB="-L$ZLIB_ROOT/lib" || LDZLIB= ; }
export LDFLAGS="-L$LHAPDF_ROOT/lib -L$CGAL_ROOT/lib -L$GMP_ROOT/lib $LDZLIB -L${GSL_ROOT}/lib"
./configure                        \
    --prefix="$INSTALLROOT"        \
    --with-thepeg="${THEPEG_ROOT}" \
    --with-openloops=${OPENLOOPS_ROOT} \
    --with-madgraph=${MADGRAPH_ROOT} \
    --with-gsl="${GSL_ROOT}"

make ${JOBS:+-j $JOBS}
make install

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
# Our environment
set HERWIG_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv HERWIG_ROOT \$HERWIG_ROOT
setenv HERWIG_INSTALL_PATH \$::env(HERWIG_ROOT)/lib/Herwig
prepend-path PATH \$HERWIG_ROOT/bin
prepend-path LD_LIBRARY_PATH \$HERWIG_ROOT/lib/Herwig
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
