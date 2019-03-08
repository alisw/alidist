package: Jiskefet-Api-Cpp
version: "%(tag_basename)s"
tag: v0.2.3
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - cpprestsdk
  - OpenSSL:(?!osx)
build_requires:
  - CMake
source: https://github.com/PascalBoeschoten/jiskefet-api-cpp
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost)
          [[ $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl)
          ;;
esac

cmake $SOURCEDIR                                    \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT           \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}    \
      ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT} \
      -DCPPREST_ROOT=${CPPRESTSDK_ROOT}          \
      -DCPPREST_LIB=${CPPRESTSDK_ROOT}/lib64/libcpprest.so \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
make ${JOBS+-j $JOBS} install

#ModuleFile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION
module load BASE/1.0                                                          \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}            \\
            ${OPENSSL_VERSION:+OpenSSL/$OPENSSL_VERSION-$OPENSSL_REVISION}            \\
            ${CPPRESTSDK_VERSION:+cpprestsdk/$CPPRESTSDK_VERSION-$CPPRESTSDK_REVISION} \\
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
set JISKEFET_API_CPP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(JISKEFET_API_CPP_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(JISKEFET_API_CPP_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(JISKEFET_API_CPP_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
