package: cgal
version: "4.6.3"
requires:
  - boost
build_requires:
  - GMP
  - MPFR
  - CMake
  - curl
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
esac
URL="https://github.com/CGAL/cgal/releases/download/releases%2FCGAL-$PKGVERSION/CGAL-$PKGVERSION.tar.xz"

curl -kLo cgal.tar.xz "$URL"
tar xJf cgal.tar.xz
cd CGAL-*

if [[ "$BOOST_ROOT" != '' ]]; then
  export LDFLAGS="-L$BOOST_ROOT/lib"
  export LD_LIBRARY_PATH="$BOOST_ROOT/lib:$LD_LIBRARY_PATH"
  export DYLD_LIBRARY_PATH="$BOOST_ROOT/lib:$LD_LIBRARY_PATH"
fi

export MPFR_LIB_DIR="${MPFR_ROOT}/lib"
export MPFR_INC_DIR="${MPFR_ROOT}/include"
export GMP_LIB_DIR="${GMP_ROOT}/lib"
export GMP_INC_DIR="${GMP_ROOT}/include"

cmake . \
      -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}" \
      -DCMAKE_INSTALL_LIBDIR:PATH="lib" \
      -DCMAKE_BUILD_TYPE=Release \
      -DWITH_BLAS:BOOL=OFF \
      -DWITH_CGAL_Core:BOOL=ON \
      -DWITH_CGAL_ImageIO:BOOL=ON \
      -DWITH_CGAL_Qt3:BOOL=OFF \
      -DWITH_CGAL_Qt4:BOOL=OFF \
      -DWITH_CGAL_Qt5:BOOL=OFF \
      -DWITH_Coin3D:BOOL=OFF \
      -DWITH_ESBTL:BOOL=OFF \
      -DWITH_Eigen3:BOOL=OFF \
      -DWITH_GMP:BOOL=ON \
      -DWITH_GMPXX:BOOL=OFF \
      -DWITH_IPE:BOOL=OFF \
      -DWITH_LAPACK:BOOL=OFF \
      -DWITH_LEDA:BOOL=OFF \
      -DWITH_MPFI:BOOL=OFF \
      -DWITH_MPFR:BOOL=ON \
      -DWITH_NTL:BOOL=OFF \
      -DWITH_OpenGL:BOOL=OFF \
      -DWITH_OpenNL:BOOL=OFF \
      -DWITH_QGLViewer:BOOL=OFF \
      -DWITH_RS:BOOL=OFF \
      -DWITH_RS3:BOOL=OFF \
      -DWITH_TAUCS:BOOL=OFF \
      -DWITH_ZLIB:BOOL=ON \
      -DWITH_demos:BOOL=OFF \
      -DWITH_examples:BOOL=OFF \
      -DCGAL_ENABLE_PRECONFIG:BOOL=NO \
      -DCGAL_IGNORE_PRECONFIGURED_GMP:BOOL=YES \
      -DCGAL_IGNORE_PRECONFIGURED_MPFR:BOOL=YES \
      ${BOOST_ROOT:+-DBoost_NO_SYSTEM_PATHS:BOOL=TRUE -DBOOST_ROOT:PATH="$BOOST_ROOT"}

make VERBOSE=1 ${JOBS:+-j$JOBS}
make install VERBOSE=1

find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath @loader_path/../lib {} \;
find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -add_rpath ${INSTALLROOT}/lib {} \;
find $INSTALLROOT/lib/ -name "*.dylib" -exec install_name_tool -id {} {} \;

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
module load BASE/1.0 ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
set CGAL_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv CGAL_ROOT \$CGAL_ROOT
prepend-path PATH \$CGAL_ROOT/bin
prepend-path LD_LIBRARY_PATH \$CGAL_ROOT/lib
EoF
