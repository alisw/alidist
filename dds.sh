package: DDS
version: "3.5.13"
source: https://github.com/FairRootGroup/DDS
requires:
  - boost
build_requires:
  - CMake
  - alibuild-recipe-tools
incremental_recipe: |
  case $ARCHITECTURE in
    osx*) ;;
    *) make -j$JOBS wn_bin ;;
  esac
  make -j$JOBS install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
case $ARCHITECTURE in
  osx*)
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost` ;;
esac

[[ $GCC_TOOLCHAIN_ROOT ]] && export DDS_LD_LIBRARY_PATH="$GCC_TOOLCHAIN_ROOT/lib64"

cmake $SOURCEDIR                                                         \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT -DBoost_NO_SYSTEM_PATHS=ON} \
      -DCMAKE_INSTALL_LIBDIR=lib

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

find $INSTALLROOT -path "*/lib/libboost_*" -delete
rm -f "$INSTALLROOT/LICENSE"

# ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
cat >> etc/modulefiles/$PKGNAME <<EoF
setenv DDS_ROOT \$PKG_ROOT
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
