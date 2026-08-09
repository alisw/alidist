package: thrift
version: "%(tag_basename)s"
tag: v0.22.0
source: https://github.com/apache/thrift
requires:
  - boost
license: Apache-2.0
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

cmake $SOURCEDIR -GNinja                                    \
        -DBoost_DIR="${BOOST_ROOT}"                         \
        -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"               \
        -DBUILD_TESTING=OFF                                 \
        -DBUILD_TUTORIALS=OFF                               \
        -DBUILD_COMPILER=ON                                 \
        -DBUILD_CPP=ON                                      \
        -DBUILD_C_GLIB=OFF                                  \
        -DBUILD_JAVA=OFF                                    \
        -DBUILD_JAVASCRIPT=OFF                              \
        -DBUILD_KOTLIN=OFF                                  \
        -DBUILD_NODEJS=OFF                                  \
        -DBUILD_PYTHON=OFF                                  \
        -DWITH_LIBEVENT=OFF                                 \
        -DWITH_ZLIB=ON                                      \
        -DWITH_OPENSSL=ON
cmake --build . -- ${JOBS+-j $JOBS} install

# install the compilation database so that we can post-check the code
cp compile_commands.json ${INSTALLROOT}

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
prepend-path PATH \$BASEDIR/$PKGNAME/\$version/bin
prepend-path LD_LIBRARY_PATH \$BASEDIR/$PKGNAME/\$version/lib
EoF
