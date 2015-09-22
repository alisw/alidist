package: fastjet
version: "v3.0.6_1.012"
requires:
  - cgal
---
#!/bin/bash -e

VerWithoutV=${PKGVERSION:1}
VerFJContrib="${VerWithoutV#*_}"
VerFJ="${VerWithoutV%%_*}"

UrlFJ="http://fastjet.fr/repo/fastjet-${VerFJ}.tar.gz"
UrlFJContrib="http://fastjet.hepforge.org/contrib/downloads/fjcontrib-${VerFJContrib}.tar.gz"

curl -Lo fastjet.tar.gz "$UrlFJ"
curl -Lo fjcontrib.tar.gz "$UrlFJContrib"

tar xzf fastjet.tar.gz
tar xzf fjcontrib.tar.gz

export LD_LIBRARY_PATH="$BOOST_ROOT/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$BOOST_ROOT/lib:$LIBRARY_PATH"

# FastJet
cd $BUILDDIR/fastjet-$VerFJ
case $ARCHITECTURE in
  slc*) LINUX_CXXFLAGS="-Wl,--no-as-needed" ;;
esac

export CXXFLAGS="$LINUX_CXXFLAGS -L$GMP_ROOT/lib -lgmp -L$MPFR_ROOT/lib -lmpfr -L$BOOST_ROOT/lib -lboost_thread -lboost_system -L$CGAL_ROOT/lib -I$BOOST_ROOT/include -I$CGAL_ROOT/include -I$GMP_ROOT/include -I$MPFR_ROOT/include -DCGAL_DO_NOT_USE_MPZF -O2 -g"
export CFLAGS="$CXXFLAGS"
export CPATH="$BOOST_ROOT/include:$CGAL_ROOT/include:$GMP_ROOT/include:$MPFR_ROOT/include"
export C_INCLUDE_PATH="$BOOST_ROOT/include:$CGAL_ROOT/include:$GMP_ROOT/include:$MPFR_ROOT/include"
./configure --enable-shared \
            --enable-cgal \
            --with-cgal=$CGAL_ROOT \
            --prefix=$INSTALLROOT \
            --enable-allcxxplugins
make ${JOBS:+-j$JOBS}
make install

# FastJet Contrib
cd $BUILDDIR/fjcontrib-$VerFJContrib
./configure --fastjet-config=$INSTALLROOT/bin/fastjet-config \
            CXXFLAGS="$CXXFLAGS" \
            CFLAGS="$CFLAGS" \
            CPATH="$CPATH" \
            C_INCLUDE_PATH="$C_INCLUDE_PATH"
make ${JOBS:+-j$JOBS}
make install
make fragile-shared ${JOBS:+-j$JOBS}
make fragile-shared-install

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
