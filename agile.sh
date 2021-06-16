package: AGILe
version: "%(tag_basename)s"
tag: "v1.4.1-alice3"
source: https://github.com/alisw/AGILe.git
requires:
  - "GCC-Toolchain:(?!osx)"
  - boost
  - lhapdf5
  - HepMC
  - Python-modules
build_requires:
  - "autotools:(slc6|slc7)"
  - SWIG
  - alibuild-recipe-tools
---
#!/bin/bash -e

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
  ;;
  *)
    ARCH_LDFLAGS="-Wl,--no-as-needed"
  ;;
esac

rsync -a --delete --exclude '**/.git' $SOURCEDIR/ ./

autoreconf -ifv
./configure                                 \
  ${BOOST_ROOT:+--with-boost="$BOOST_ROOT"} \
  --with-hepmc="$HEPMC_ROOT"                \
  --prefix="$INSTALLROOT"
make -j$JOBS
make install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --root-env --extra > "$MODULEDIR/$PKGNAME" <<\EoF
prepend-path PYTHONPATH $PKG_ROOT/lib/python2.7/site-packages
EoF
