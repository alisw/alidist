package: KFParticle
version: "alice-v1.1-1"
tag: "alice/v1.1-1"
source: https://github.com/alisw/KFParticle
requires:
  - ROOT
  - "GCC-Toolchain:(?!osx)"
  - Vc
build_requires:
  - CMake
---
#!/bin/bash -e

cmake $SOURCEDIR                                        \
      ${VC_REVISION:+-DVc_INCLUDE_DIR=$VC_ROOT/include}  \
      ${VC_VERSIOM:+-DVc_LIBRARIES=$VCROOT/lib/libVc.a} \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT               \
      -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"            \
      -DFIXTARGET=FALSE
make ${JOBS+-j $JOBS} install

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
module load BASE/1.0 ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${VC_REVISION:+Vc/$VC_VERSION-$VC_REVISION} ${ROOT_REVISION:+ROOT/$ROOT_VERSION-$ROOT_REVISION}
# Our environment
setenv KFPARTICLE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path ROOT_INCLUDE_PATH \$::env(BASEDIR)/$PKGNAME/\$version/include
prepend-path LD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(BASEDIR)/$PKGNAME/\$version/lib")
EoF
