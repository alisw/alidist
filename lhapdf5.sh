package: lhapdf5
version: v5.9.1
---
#!/bin/bash -ex

ARCHIVE="lhapdf-5.9.1.tar.gz"
URL="https://www.hepforge.org/archive/lhapdf/${ARCHIVE}"

cd $SOURCEDIR
curl -O "${URL}"
tar xz --strip-components 1 -f ${ARCHIVE}

cd $BUILDDIR
rsync -a $SOURCEDIR/ $BUILDDIR/

./configure --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS} all
make install

cd $INSTALLROOT/share/lhapdf
$INSTALLROOT/bin/lhapdf-getdata cteq6l

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
module load BASE/1.0 yaml-cpp/$YAML_CPP_VERSION-$YAML_CPP_REVISION boost/$BOOST_VERSION-$BOOST_REVISION autotools/$AUTOTOOLS_VERSION-$AUTOTOOLS_REVISION
# Our environment
setenv LHAPDF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(LHAPDF_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(LHAPDF_ROOT)/lib
EoF
