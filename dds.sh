package: DDS
version: "%(tag_basename)s"
tag: "2.2"
source: https://github.com/FairRootGroup/DDS
requires:
  - boost
build_requires:
  - CMake
incremental_recipe: |
  case $ARCHITECTURE in
    osx*) ;;
    *) make -j$JOBS wn_bin ;;
  esac
  make -j$JOBS install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex

case $ARCHITECTURE in
  osx*)
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost` ;;
esac

[[ $GCC_TOOLCHAIN_ROOT ]] && export DDS_LD_LIBRARY_PATH="$GCC_TOOLCHAIN_ROOT/lib64"

cmake $SOURCEDIR                                                         \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT -DBoost_NO_SYSTEM_PATHS=ON} \

# Limit the number of build processes to avoid exahusting memory when building
# on smaller machines.
JOBS=$((${JOBS:-1}*2/5))
[[ $JOBS -gt 0 ]] || JOBS=1

# This is needed because https://github.com/Homebrew/homebrew-core/pull/35735
# seems to break the creation of the tarball.
case $ARCHITECTURE in
  osx*) ;;
  *) make -j$JOBS wn_bin ;;
esac

make -j$JOBS install

# ModuleFile
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
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION} ${GCC_TOOLCHAIN_VERSION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv DDS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(DDS_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(DDS_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(DDS_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
