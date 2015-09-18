package: YODA
version: "v1.4.0"
requires:
  - boost
  - Python
prepend_path:
  PYTHONPATH: "$(yoda-config --pythonpath)"
---
#!/bin/bash -e
Url="http://www.hepforge.org/archive/yoda/YODA-${PKGVERSION:1}.tar.bz2"

curl -Lo yoda.tar.bz2 "$Url"
tar xjf yoda.tar.bz2
cd YODA-${PKGVERSION:1}
./configure --prefix="$INSTALLROOT" --with-boost="$Boost"
make -j$JOBS
make install -j$JOBS

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
module load BASE/1.0 boost/$BOOST_VERSION-$BOOST_REVISION Python/$PYTHON_VERSION-$PYTHON_REVISION
# Our environment
setenv YODA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(YODA_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(YODA_ROOT)/lib
set pythonpath [exec yoda-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
EoF
