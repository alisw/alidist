# Online Device Control
package: ODC
version: "0.84.2-alice2"
tag: "0.85.0"
source: https://github.com/FairRootGroup/ODC.git
requires:
  - boost
  - protobuf
  - DDS
  - FairLogger
  - FairMQ
  - grpc
  - libInfoLogger
build_requires:
  - flatbuffers
  - CMake
  - GCC-Toolchain:(?!osx.*)
  - ninja
---

case $ARCHITECTURE in
  osx*)
    # If we preferred system tools, we need to make sure we can pick them up.
    [[ ! $BOOST_ROOT ]] && BOOST_ROOT=`brew --prefix boost`
    [[ ! $PROTOBUF_ROOT ]] && PROTOBUF_ROOT=`brew --prefix protobuf`
    [[ ! $GSL_ROOT ]] && GSL_ROOT=`brew --prefix gsl`
    [[ ! $GRPC_ROOT ]] && GRPC_ROOT=`brew --prefix grpc`
    # grpc needs OpenSSL and doesn't find it by default.
    [[ ! $OPENSSL_ROOT ]] && OPENSSL_ROOT=$(brew --prefix openssl@3)

    SONAME=dylib
  ;;
  *) SONAME=so ;;
esac



cmake  $SOURCEDIR                                                                            \
       -G Ninja                                                                              \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                   \
       ${DDS_ROOT:+-DDDS_PATH=$DDS_ROOT}                                                     \
       ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                                               \
       -DBoost_NO_SYSTEM_PATHS=${BOOST_NO_SYSTEM_PATHS}                                      \
       -DProtobuf_ROOT=${PROTOBUF_ROOT}                                                      \
       ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                                               \
       -DCMAKE_EXPORT_COMPILE_COMMANDS=ON                                                    \
       -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                                                   \
       -DgRPC_ROOT=$GRPC_ROOT                                                                \
       ${OPENSSL_ROOT:+-DOPENSSL_ROOT_DIR="$OPENSSL_ROOT"}                                   \
       ${OPENSSL_ROOT:+-DOPENSSL_INCLUDE_DIRS=$OPENSSL_ROOT/include}                         \
       ${OPENSSL_ROOT:+-DOPENSSL_LIBRARIES=$OPENSSL_ROOT/lib/libssl.$SONAME;$OPENSSL_ROOT/lib/libcrypto.$SONAME} \
       -DBUILD_INFOLOGGER=ON

cmake --build . -- ${JOBS:+-j $JOBS} install

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
# This really means we are in development mode. We need to make sure we
# use the real path for sources in this case. We also copy the
# compile_commands.json file so that IDEs can make use of it directly, this
# is a departure from our "no changes in sourcecode" policy, but for a good reason
# and in any case the file is in gitignore.
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
fi


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
