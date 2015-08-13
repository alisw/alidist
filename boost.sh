package: boost
version: v1.57.0
source: https://github.com/alisw/boost.git
tag: v1.57.0
---
#!/bin/sh

case $ARCHITECTURE in 
  osx*) TOOLSET=darwin ;;
  *) TOOLSET=gcc ;;
esac

rsync -a $SOURCEDIR/ $BUILDDIR/
cd $BUILDDIR/tools/build
  sh bootstrap.sh ${TOOLSET}
  mkdir $BUILDDIR/tmp-boost-build
  ./b2 install --prefix=$BUILDDIR/tmp-boost-build
  export PATH=${BUILDDIR}/tmp-boost-build/bin:${PATH}
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
   --without-exception \
   --without-graph \
   --without-graph_parallel \
   --without-locale \
   --without-log \
   --without-math \
   --without-mpi \
   --without-python \
   --without-random \
   --without-wave \
   toolset=${TOOLSET} \
   link=shared \
   threading=multi \
   variant=release \
   install
