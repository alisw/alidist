package: lhapdf
version: v6.1.5
source: https://github.com/alisw/LHAPDF
requires:
 - yaml-cpp
 - boost
build_requires:
 - autotools
---
#!/bin/bash -ex

rsync -a $SOURCEDIR/ $BUILDDIR/

case $PKGVERSION in
  v6.0*) WITH_YAML_CPP="--with-yaml-cpp=${YAML_CPP_ROOT}"
esac

# Bug in LHAPDF: still uses $(builddir) which was deprecated and it has been
# dropped in recent versions of automake. By default it is set to ".", the
# current directory, so we force-substitute it as such.
find . -name Makefile.in -or -name Makefile.am \
       -exec grep -Hl '$(builddir)' '{}' \; | \
       while read FILE; do
         sed -i.bak -e 's|$(builddir)|.|g' $FILE
       done

autoreconf -ivf
./configure --prefix=$INSTALLROOT \
            --with-boost=$BOOST_ROOT \
            $WITH_YAML_CPP

make ${JOBS+-j $JOBS} all
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
module load BASE/1.0 yaml-cpp/$YAML_CPP_VERSION-$YAML_CPP_REVISION boost/$BOOST_VERSION-$BOOST_REVISION autotools/$AUTOTOOLS_VERSION-$AUTOTOOLS_REVISION
# Our environment
setenv LHAPDF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(LHAPDF_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(LHAPDF_ROOT)/lib
EoF
