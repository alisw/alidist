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
  - GSL
build_requires:
  - "autotools:(slc6|slc7)"
  - SWIG
  - alibuild-recipe-tools
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! -n $GSL_ROOT ]] && GSL_ROOT=$(brew --prefix gsl)
  ;;
esac

rsync -a --chmod=ug=rwX --exclude='**/.git' --delete --delete-excluded "$SOURCEDIR/" ./

sed -i -e '1s|#!.*python|#!/usr/bin/env python3|' pyext/setup.py.in pyext/ez_setup.py

autoreconf -ifv
./configure                                 \
  ${BOOST_ROOT:+--with-boost="$BOOST_ROOT"} \
  --with-hepmc="$HEPMC_ROOT"                \
  --prefix="$INSTALLROOT"
make -j$JOBS
make install

PYVER="$(find $INSTALLROOT/lib -type d -name 'python*' -exec basename {} \; | head -n 1)"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
$(alibuild-generate-module --lib --bin)
set AGILE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv AGILE_ROOT \$AGILE_ROOT
prepend-path PYTHONPATH \$AGILE_ROOT/lib/$PYVER/site-packages
EoF
