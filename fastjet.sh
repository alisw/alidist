package: fastjet
version: "%(tag_basename)s"
tag: "v3.2.1_1.024-alice3"
source: https://github.com/alisw/fastjet
requires:
  - cgal
  - GMP
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

if [[ $GGAL_ROOT ]]; then
  export LIBRARY_PATH="${BOOST_ROOT:+$BOOST_ROOT/lib:}$LIBRARY_PATH"
  BOOST_INC=${BOOST_ROOT:+$BOOST_ROOT/include:}
  printf "void main() {}" | c++ -xc ${BOOST_ROOT:+-L$BOOST_ROOT/lib} -lboost_thread - -o /dev/null 2>/dev/null  \
    && BOOST_LIBS="${BOOST_ROOT+-L$BOOST_ROOT/lib} -lboost_thread"                                              \
    || BOOST_LIBS="${BOOST_ROOT+-L$BOOST_ROOT/lib} -lboost_thread-mt"
  BOOST_LIBS="$BOOST_LIBS -lboost_system"
fi

rsync -a --delete --cvs-exclude --exclude .git $SOURCEDIR/ ./

# FastJet
pushd fastjet
  autoreconf -i -v -f
  [[ "${ARCHITECTURE:0:3}" != osx ]] && ARCH_FLAGS='-Wl,--no-as-needed'
  FJTAG=${GIT_TAG#alice-}
  if [[ $FJTAG < "v3.3.3" ]]
  then
    ADDITIONAL_FLAGS="${GMP_ROOT:+-L$GMP_ROOT/lib -lgmp} ${MPFR_ROOT:+-L$MPFR_ROOT/lib -lmpfr} $BOOST_LIBS ${CGAL_ROOT:+-L$CGAL_ROOT/lib -lCGAL -I$CGAL_ROOT/include} ${BOOST_ROOT:+-I$BOOST_ROOT/include} ${GMP_ROOT:+-I$GMP_ROOT/include} ${MPFR_ROOT:+-I$MPFR_ROOT/include} ${CGAL_ROOT:+-DCGAL_DO_NOT_USE_MPZF} -O2 -g"
    export CXXFLAGS="$CXXFLAGS $ARCH_FLAGS $ADDITIONAL_FLAGS"
    export CFLAGS="$CFLAGS $ARCH_FLAGS $ADDITIONAL_FLAGS"
    export CPATH="${BOOST_INC}${CGAL_ROOT:+$CGAL_ROOT/include:}${GMP_ROOT:+$GMP_ROOT/include:}${MPFR_ROOT:+$MPFR_ROOT/include}"
    export C_INCLUDE_PATH="${BOOST_INC}${GMP_ROOT:+$GMP_ROOT/include:}${MPFR_ROOT:+$MPFR_ROOT/include}"
    ./configure --enable-shared \
                ${CGAL_ROOT:+--enable-cgal --with-cgal=$CGAL_ROOT} \
                --prefix=$INSTALLROOT \
                --enable-allcxxplugins
  else
    export CXXFLAGS="$CXXFLAGS $ARCH_FLAGS"
    ./configure --enable-shared         \
                ${CGAL_ROOT:+--enable-cgal \
                --with-cgaldir=$CGAL_ROOT  \
                --with-cgal-boostdir=$BOOST_ROOT  \
                ${GMP_ROOT:+--with-cgal-gmpdir=$GMP_ROOT}  \
                ${MPFR_ROOT:+--with-cgal-mpfrdir=$MPFR_ROOT}}  \
                --prefix=$INSTALLROOT   \
                --enable-allcxxplugins  \
		--disable-auto-ptr
  fi
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

# Dependencies relocation: rely on runtime environment.  That is,
# specific paths in the generated script are replaced by expansions of
# the relevant environment variables.
SED_EXPR="s!x!x!"  # noop
for P in $REQUIRES $BUILD_REQUIRES; do
  UPPER=$(echo $P | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  EXPAND=$(eval echo \$${UPPER}_ROOT)
  [[ $EXPAND ]] || continue
  SED_EXPR="$SED_EXPR; s!$EXPAND!\$${UPPER}_ROOT!g"
done

# Modify fastjet-config to use environment
cat $INSTALLROOT/bin/fastjet-config | sed -e "$SED_EXPR" > $INSTALLROOT/bin/fastjet-config.0
mv $INSTALLROOT/bin/fastjet-config.0 $INSTALLROOT/bin/fastjet-config
chmod 0755 $INSTALLROOT/bin/fastjet-config

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
module load BASE/1.0 ${CGAL_REVISION:+cgal/$CGAL_VERSION-$CGAL_REVISION} ${GMP_REVISION:+GMP/$GMP_VERSION-$GMP_REVISION}
# Our environment
set FASTJET_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv FASTJET \$FASTJET_ROOT
prepend-path PATH \$FASTJET_ROOT/bin
prepend-path LD_LIBRARY_PATH \$FASTJET_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$FASTJET_ROOT/include
EoF
