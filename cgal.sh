package: CGAL
version: "4.4"
requires:
  - boost
---
#!/bin/bash -e
PKGID=33524
Url="https://gforge.inria.fr/frs/download.php/${PKGID}/Cgal-${PKGVERSION}.tar.bz2"

curl -Lo cgal.tar.bz2 "$Url"
tar xjf cgal.tar.bz2
cd CGAL-$PKGVERSION
export LDFLAGS="-L$BOOST_ROOT/lib ${LDFLAGS}"
export LD_LIBRARY_PATH="${BOOST_ROOT}/lib:${LD_LIBRARY_PATH}"

#export MPFR_LIB_DIR="${MPFR_STATIC_ROOT}/lib"
#export MPFR_INC_DIR="${MPFR_STATIC_ROOT}/include"
#export GMP_LIB_DIR="${GMP_STATIC_ROOT}/lib"
#export GMP_INC_DIR="${GMP_STATIC_ROOT}/include"

cmake . \
      -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}" \
      -DCMAKE_SKIP_RPATH:BOOL=YES \
      -DWITH_BLAS:BOOL=OFF \
      -DWITH_CGAL_Core:BOOL=ON \
      -DWITH_CGAL_ImageIO:BOOL=ON \
      -DWITH_CGAL_Qt3:BOOL=OFF \
      -DWITH_CGAL_Qt4:BOOL=OFF \
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
      -DBoost_NO_SYSTEM_PATHS:BOOL=TRUE \
      -DBOOST_ROOT:PATH="${BOOST_ROOT}"


make VERBOSE=1

make install VERBOSE=1

# Modulefile
ModuleDir="${INSTALLROOT}/etc/Modules/modulefiles/${PKGNAME}"
mkdir -p "$ModuleDir"
cat > "${ModuleDir}/${PKGVERSION}-${PKGREVISION}" <<EoF
#%Module1.0#####################################################################
##
## ALICE - CGAL modulefile
##

proc ModulesHelp { } {
        global version
        puts stderr "This module is a module of the ALICE for CGAL."
}

set     version         ${PKGVERSION}

module-whatis   "CGAL versions module for the ALICE"

####################################################

module load BASE/1.0 boost/v1_53_0

## -- CGAL --
setenv          CGAL            \$::env(BASEDIR)/cgal/\$version

append-path     LD_LIBRARY_PATH \$::env(CGAL)/lib
EoF
