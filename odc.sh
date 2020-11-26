#Online Device Control
package: ODC
version: "%(tag_basename)s"
tag: 0.12
source: https://github.com/FairRootGroup/ODC.git
requires:
- boost
- protobuf
- DDS
- FairLogger
- FairMQ
- grpc
build_requires:
  - CMake
  - GCC-Toolchain:(?!osx.*)
---

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=`brew --prefix protobuf`
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    [[ ! $GRPC_ROOT ]] && GRPC_ROOT=`brew --prefix grpc`

    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac



cmake  $SOURCEDIR                                                                            \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                   \
       ${DDS_ROOT:+-DDDS_PATH=$DDS_ROOT}                                                     \
       ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                               \
       -DBoost_NO_SYSTEM_PATHS=${BOOST_NO_SYSTEM_PATHS}                                      \
       -DProtobuf_ROOT=${PROTOBUF_ROOT}                                                      \
       ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                               \
       -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                                    \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                   \
       -DgRPC_ROOT=$GRPC_ROOT


make ${JOBS+-j $JOBS}
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
module load BASE/1.0                                                                                \\
            ${FAIRLOGGER_REVISION:+FairLogger/$FAIRLOGGER_VERSION-$FAIRLOGGER_REVISION}             \\
            ${FAIRMQ_REVISION:+FairMQ/$FAIRMQ_VERSION-$FAIRMQ_REVISION}                             \\
            ${PROTOBUF_REVISION:+protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION}                     \\
            ${BOOST_REVISION:+boost/$BOOST_VERSION-$BOOST_REVISION}                                 \\
            ${DDS_REVISION:+DDS/$DDS_VERSION-$DDS_REVISION}                                         \\
            ${GRPC_REVISION:+grpc/$GRPC_VERSION-$GRPC_REVISION}                                     \\
            ${GCC_TOOLCHAIN_REVISION:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
            
# Our environment
set ODC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$ODC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$ODC_ROOT/lib
prepend-path LD_LIBRARY_PATH \$ODC_ROOT/lib64
EoF
