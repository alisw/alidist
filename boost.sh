package: boost
version: "%(tag_basename)s"
source: https://github.com/alisw/boost.git
tag: v1.59.0
requires:
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/bash -e
TMPB2=$BUILDDIR/tmp-boost-build
case $ARCHITECTURE in 
  osx*) TOOLSET=darwin ;;
  *) TOOLSET=gcc ;;
esac

rsync -a $SOURCEDIR/ $BUILDDIR/
cd $BUILDDIR/tools/build
bash bootstrap.sh $TOOLSET
mkdir -p $TMPB2
./b2 install --prefix=$TMPB2
export PATH=$TMPB2/bin:$PATH
cd $BUILDDIR
b2 -q \
   -d2 \
   ${JOBS+-j $JOBS} \
   --prefix=$INSTALLROOT \
   --build-dir=build-boost \
   --disable-icu \
   --without-atomic \
   --without-chrono \
   --without-container \
   --without-context \
   --without-coroutine \
   --without-graph \
   --without-graph_parallel \
   --without-locale \
   --without-math \
   --without-mpi \
   --without-python \
   --without-wave \
   toolset=$TOOLSET \
   link=shared \
   threading=multi \
   variant=release \
   $EXTRA_CXXFLAGS \
   install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv BOOST_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(BOOST_ROOT)/lib
EoF
