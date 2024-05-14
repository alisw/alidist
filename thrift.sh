package: thrift
version: "%(tag_basename)s"
tag: 0.12.0
source: https://github.com/apache/thrift
requires:
  - boost
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - "OpenSSL:(?!osx)"
  - yacc-like
prefer_system: ".*"
prefer_system_check: |
  thrift --version
---

case $ARCHITECTURE in
  osx*) 
    export PATH=$(brew --prefix bison)/bin:$PATH
    OPENSSL_ROOT=$(brew --prefix openssl@3)
  ;;
esac
rsync -a --delete --exclude="**/.git" $SOURCEDIR/ ./
./bootstrap.sh
./configure --prefix ${INSTALLROOT}     \
            --with-boost=${BOOST_ROOT}  \
            --without-erlang            \
            --without-haskell           \
            --without-perl              \
            --without-python            \
            --without-java              \
            --without-php               \
            --without-php_extension     \
            --without-ruby              \
            --without-qt                \
            --enable-libs               \
            --disable-tests             \
            --disable-plugin            \
            --disable-tutorial          \
            ${OPENSSL_ROOT:+--with-openssl=${OPENSSL_ROOT}}
make CPPFLAGS="-I${BOOST_ROOT}/include ${CPPFLAGS}" CXXFLAGS="-Wno-error -fPIC -O2" ${JOBS:+-j $JOBS}
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
module load BASE/1.0 ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
set BASEDIR \$::env(BASEDIR)
prepend-path PATH \$BASEDIR/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
EoF
