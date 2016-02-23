package: fastjet
version: "%(tag_basename)s%(defaults_upper)s"
tag: "alice/v3.0.6_1.012"
source: https://github.com/alisw/fastjet
requires:
  - cgal
env:
  FASTJET: "$FASTJET_ROOT"
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
esac

export LIBRARY_PATH="${BOOST_ROOT:+$BOOST_ROOT/lib:}$LIBRARY_PATH"
BOOST_INC=${BOOST_ROOT:+$BOOST_ROOT/include:}
printf "void main() {}" | c++ -xc ${BOOST_ROOT:+-L$BOOST_ROOT/lib} -lboost_thread - -o /dev/null 2>/dev/null  \
  && BOOST_LIBS="${BOOST_ROOT+-L$BOOST_ROOT/lib} -lboost_thread"                                              \
  || BOOST_LIBS="${BOOST_ROOT+-L$BOOST_ROOT/lib} -lboost_thread-mt"
BOOST_LIBS="$BOOST_LIBS -lboost_system"

rsync -a --delete --cvs-exclude $SOURCEDIR/ ./

# FastJet
pushd fastjet
  autoreconf -i -v -f
  [[ "${ARCHITECTURE:0:3}" != osx ]] && EXTRA_CXXFLAGS='-Wl,--no-as-needed'
  export CXXFLAGS="$CXXFLAGS $EXTRA_CXXFLAGS -L$GMP_ROOT/lib -lgmp -L$MPFR_ROOT/lib -lmpfr $BOOST_LIBS -L$CGAL_ROOT/lib -lCGAL ${BOOST_ROOT:+-I$BOOST_ROOT/include} -I$CGAL_ROOT/include -I$GMP_ROOT/include -I$MPFR_ROOT/include -DCGAL_DO_NOT_USE_MPZF -O2 -g"
  export CFLAGS="$CFLAGS $CXXFLAGS"
  export CPATH="${BOOST_INC}$CGAL_ROOT/include:$GMP_ROOT/include:$MPFR_ROOT/include"
  export C_INCLUDE_PATH="${BOOST_INC}$GMP_ROOT/include:$MPFR_ROOT/include"
  ./configure --enable-shared \
              --enable-cgal \
              --with-cgal=$CGAL_ROOT \
              --prefix=$INSTALLROOT \
              --enable-allcxxplugins
  make ${JOBS:+-j$JOBS}
  make install
popd

# FastJet Contrib
pushd fjcontrib
  ./configure --fastjet-config=$INSTALLROOT/bin/fastjet-config \
              CXXFLAGS="$CXXFLAGS" \
              CFLAGS="$CFLAGS" \
              CPATH="$CPATH" \
              C_INCLUDE_PATH="$C_INCLUDE_PATH"
  make ${JOBS:+-j$JOBS}
  make install
  make fragile-shared ${JOBS:+-j$JOBS}
  make fragile-shared-install
popd

rm -f $INSTALLROOT/lib/*.la

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
module load BASE/1.0 cgal/$CGAL_VERSION-$CGAL_REVISION
# Our environment
setenv FASTJET \$::env(BASEDIR)/$PKGNAME/\$version
setenv FASTJET_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(FASTJET_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(FASTJET_ROOT)/lib
EoF
