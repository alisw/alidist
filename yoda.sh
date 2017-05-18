package: YODA
version: "v1.6.3"
source: https://github.com/alisw/yoda
requires:
  - boost
  - "Python-modules:slc[567]"
build_requires:
  - autotools
  - "Python-system:(?!slc[567])"
prepend_path:
  PYTHONPATH: $YODA_ROOT/lib64/python2.7/site-packages:$YODA_ROOT/lib/python2.7/site-packages
---
#!/bin/bash -e
rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

autoreconf -ivf
./configure --prefix="$INSTALLROOT" --with-boost="$Boost"
make -j$JOBS
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
module load BASE/1.0 boost/$BOOST_VERSION-$BOOST_REVISION ${PYTHON_VERSION:+Python/$PYTHON_VERSION-$PYTHON_REVISION} ${PYTHON_MODULES_VERSION:+Python-modules/$PYTHON_MODULES_VERSION-$PYTHON_MODULES_REVISION}
# Our environment
setenv YODA_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(YODA_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(YODA_ROOT)/lib
prepend-path LD_LIBRARY_PATH \$::env(YODA_ROOT)/lib64
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(YODA_ROOT)/lib")
set pythonpath [exec yoda-config --pythonpath]
prepend-path PYTHONPATH \$pythonpath
EoF
