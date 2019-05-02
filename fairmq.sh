package: FairMQ
version: "%(tag_basename)s"
tag: v1.4.2
source: https://github.com/FairRootGroup/FairMQ
requires:
 - boost
 - FairLogger
 - ZeroMQ
 - msgpack
 - DDS
 - asiofi
build_requires:
 - CMake
 - "GCC-Toolchain:(?!osx)"
 - googletest
incremental_recipe: |
  cmake --build . --target install ${JOBS:+-- -j$JOBS}
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
prepend_path:
  ROOT_INCLUDE_PATH: "$FAIRMQ_ROOT/include"
  ROOT_INCLUDE_PATH: "$FAIRMQ_ROOT/include/fairmq"
---
mkdir -p $INSTALLROOT

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $ZEROMQ_ROOT ]] && ZEROMQ_ROOT=`brew --prefix zeromq`
    [[ ! $MSGPACK_ROOT ]] && MSGPACK_ROOT=`brew --prefix msgpack`
  ;;
  *)
    BUILD_OFI=ON
    if [[ $(printf '%s\n' "1.4.2" "${PKGVERSION:1}" | sort -V | head -n1) != "1.4.2" ]]; then
      BUILD_OFI=OFF
    fi
  ;;
esac

cmake $SOURCEDIR                                                 \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                    \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER}        \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}  \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                        \
      ${GOOGLETEST_ROOT:+-DGTEST_ROOT=$GOOGLETEST_ROOT}          \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                    \
      ${FAIRLOGGER_ROOT:+-DFAIRLOGGER_ROOT=$FAIRLOGGER_ROOT}     \
      ${ZEROMQ_ROOT:+-DZEROMQ_ROOT=$ZEROMQ_ROOT}                 \
      ${MSGPACK_ROOT:+-DMSGPACK_ROOT=$MSGPACK_ROOT}              \
      ${DDS_ROOT:+-DDDS_ROOT=$DDS_ROOT}                          \
      ${ASIOFI_ROOT:+-DASIOFI_ROOT=$ASIOFI_ROOT}                 \
      ${OFI_ROOT:+-DOFI_ROOT=$OFI_ROOT}                          \
      ${OFI_ROOT:--DBUILD_OFI_TRANSPORT=OFF}                     \
      -DDISABLE_COLOR=ON                                         \
      -DBUILD_DDS_PLUGIN=ON                                      \
      -DBUILD_NANOMSG_TRANSPORT=OFF                              \
      ${BUILD_OFI:+-DBUILD_OFI_TRANSPORT=ON}                     \
      -DBUILD_EXAMPLES=ON                                        \
      -DCMAKE_INSTALL_LIBDIR=lib                                 \
      -DCMAKE_INSTALL_BINDIR=bin

cmake --build . --target install ${JOBS:+-- -j$JOBS}

# Tests will not run unless ALIBUILD_FAIRMQ_TESTS is set
if [[ $ALIBUILD_FAIRMQ_TESTS ]]; then
  # In order to reduce the probability of clashes, tests are not run in parallel
  ctest --output-on-failure
fi

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
module load BASE/1.0                                                                    \\
            ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}                      \\
            ${FAIRLOGGER_VERSION:+FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION}  \\
            ${ZEROMQ_VERSION:+ZeroMQ/$ZEROMQ_VERSION-$ZEROMQ_REVISION}                  \\
            ${MSGPACK_VERSION:+msgpack/$MSGPACK_VERSION-$MSGPACK_REVISION}              \\
            ${ASIOFI_VERSION:+asiofi/$ASIOFI_VERSION-$ASIOFI_REVISION}                  \\
            ${DDS_VERSION:+DDS/$DDS_VERSION-$DDS_REVISION}
# Our environment
setenv FAIRMQ_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(FAIRMQ_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(FAIRMQ_ROOT)/lib
prepend-path ROOT_INCLUDE_PATH \$::env(FAIRMQ_ROOT)/include
prepend-path ROOT_INCLUDE_PATH \$::env(FAIRMQ_ROOT)/include/fairmq
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(FAIRMQ_ROOT)/lib")
EoF
MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p $MODULEDIR && rsync -a --delete etc/modulefiles/ $MODULEDIR
