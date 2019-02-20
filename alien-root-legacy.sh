package: AliEn-ROOT-Legacy
version: "%(tag_basename)s"
tag: "0.0.4"
source: https://gitlab.cern.ch/jalien/alien-root-legacy.git
requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - ROOT
build_requires:
  - xalienfs
append_path:
  ROOT_PLUGIN_PATH: "$ALIEN_ROOT_LEGACY_ROOT/etc/plugins"
---
#!/bin/bash -e
case $ARCHITECTURE in
  osx*) [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl) ;;
esac
cmake $SOURCEDIR                                         \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"              \
      -DROOTSYS="$ROOTSYS"                               \
       ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR=$OPENSSL_ROOT} \
      -DALIEN_DIR="$XALIENFS_ROOT"                       \
      -DROOT_VERSION="$ROOT_VERSION"



make ${JOBS:+-j $JOBS} install
for RPKG in $BUILD_REQUIRES; do
  RPKG_UP=$(echo $RPKG|tr '[:lower:]' '[:upper:]'|tr '-' '_')
  RPKG_ROOT=$(eval echo "\$${RPKG_UP}_ROOT")
  rsync -a $RPKG_ROOT/ $INSTALLROOT/
  pushd $INSTALLROOT/../../..
    env WORK_DIR=$PWD sh -e $INSTALLROOT/relocate-me.sh
  popd
  rm -f $INSTALLROOT/etc/modulefiles/{$RPKG,$RPKG.unrelocated} || true
done


# Modulefile
mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ROOT/${ROOT_VERSION}-${ROOT_REVISION}

# Our environment
setenv ALIEN_ROOT_LEGACY_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(ALIEN_ROOT_LEGACY_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALIEN_ROOT_LEGACY_ROOT)/lib
append-path ROOT_PLUGIN_PATH \$::env(ALIEN_ROOT_LEGACY_ROOT)/etc/plugins
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ALIEN_ROOT_LEGACY_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
