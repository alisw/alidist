package: Jiskefet-Api-Cpp
version: "%(tag_basename)s"
tag: v0.1.0
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - cpprestsdk
  - OpenSSL
build_requires:
  - CMake
source: https://github.com/PascalBoeschoten/jiskefet-api-cpp
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost);;
esac

cmake $SOURCEDIR                                    \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT           \
      ${BOOST_VERSION:+-DBOOST_ROOT=$BOOST_ROOT}    \
      -DCPPREST_ROOT=${CPPRESTSDK_ROOT}          \
      -DCPPREST_LIB=${CPPRESTSDK_ROOT}/lib64/libcpprest \
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
            ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}

# Our environment
setenv JISKEFET_API_CPP_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(JISKEFET_API_CPP_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(JISKEFET_API_CPP_ROOT)/lib
prepend-path PYTHONPATH \$::env(JISKEFET_API_CPP_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(JISKEFET_API_CPP_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
