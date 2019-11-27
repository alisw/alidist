package: Rivet-hi
version: "%(tag_basename)s"
tag: v2.6.0-alice2
source: https://github.com/alisw/rivet-hi
requires:
  - GSL
  - YODA
  - fastjet
  - HepMC
  - boost
build_requires:
  - GCC-Toolchain:(?!osx)
prepend_path:
  PYTHONPATH: $RIVET_HI_ROOT/lib64/python2.7/site-packages:$RIVET_HI_ROOT/lib/python2.7/site-packages
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
  ;;
  *)
    ARCH_LDFLAGS="-Wl,--no-as-needed"
  ;;
esac

rsync -a --exclude='**/.git' --delete --delete-excluded $SOURCEDIR/ ./

# MPFR and GMP are compiled statically, however in some cases there might be
# some "-lgmp" left somewhere and we have to deal with it with the correct path.
# Boost flags are also necessary
export LDFLAGS="$ARCH_LDFLAGS -L${MPFR_ROOT}/lib -L${GMP_ROOT}/lib -L${CGAL_ROOT}/lib -lCGAL"
export LIBRARY_PATH="$LD_LIBRARY_PATH"
export CXXFLAGS="$CXXFLAGS -I${MPFR_ROOT}/include -I${GMP_ROOT}/include -I${CGAL_ROOT}/include -DCGAL_DO_NOT_USE_MPZF"

if [[ "$BOOST_ROOT" != '' ]]; then
  export LDFLAGS="$LDFLAGS -L$BOOST_ROOT/lib"
  export CXXFLAGS="$CXXFLAGS -I$BOOST_ROOT/include"
fi
if printf "int main(){}" | c++ $LDFLAGS -lboost_thread -lboost_system -xc++ - -o /dev/null; then
  export LDFLAGS="$LDFLAGS -lboost_thread -lboost_system"
else
  export LDFLAGS="$LDFLAGS -lboost_thread-mt -lboost_system-mt"
fi

[[ "$CXXFLAGS" != *'-std=c++11'* ]] || CXX11=1

(
unset PYTHON_VERSION
autoreconf -ivf
./configure                                 \
  --prefix="$INSTALLROOT"                   \
  --disable-doxygen                         \
  --with-yoda="$YODA_ROOT"                  \
  ${GSL_ROOT:+--with-gsl="$GSL_ROOT"}       \
  --with-hepmc="$HEPMC_ROOT"                \
  --with-fastjet="$FASTJET_ROOT"            \
  ${BOOST_ROOT:+--with-boost="$BOOST_ROOT"} \
  ${CXX11:+--enable-stdcxx11}
make -j$JOBS
make install
)

# Dependencies relocation: rely on runtime environment
SED_EXPR="s!x!x!"  # noop
for P in $REQUIRES $BUILD_REQUIRES; do
  UPPER=$(echo $P | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  EXPAND=$(eval echo \$${UPPER}_ROOT)
  [[ $EXPAND ]] || continue
  SED_EXPR="$SED_EXPR; s!$EXPAND!\$${UPPER}_ROOT!g"
done
cat $INSTALLROOT/bin/rivet-config | sed -e "$SED_EXPR" > $INSTALLROOT/bin/rivet-config.0
mv $INSTALLROOT/bin/rivet-config.0 $INSTALLROOT/bin/rivet-config
chmod 0755 $INSTALLROOT/bin/rivet-config

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
module load BASE/1.0 ${GSL_REVISION:+GSL/$GSL_VERSION-$GSL_REVISION} YODA/$YODA_VERSION-$YODA_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION HepMC/$HEPMC_VERSION-$HEPMC_REVISION
# Our environment
# TODO: RIVETHI_ROOT is wrong (it should be RIVET_HI_ROOT) and it is deprecated
# in favour of using rivet-config --prefix. Leaving it for now, but it will be
# removed upon PWGMM's decision in the future
set RIVETHI_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$RIVETHI_ROOT/lib/python2.7/site-packages
prepend-path PYTHONPATH \$RIVETHI_ROOT/lib64/python2.7/site-packages
prepend-path PATH \$RIVETHI_ROOT/bin
prepend-path LD_LIBRARY_PATH \$RIVETHI_ROOT/lib
EoF
