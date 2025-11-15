package: Monitoring
version: "%(tag_basename)s"
tag: v3.19.8
requires:
  - boost
  - "GCC-Toolchain:(?!osx)"
  - curl
  - libInfoLogger
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja
source: https://github.com/AliceO2Group/Monitoring
incremental_recipe: |
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -ex
case $ARCHITECTURE in
    osx*) [[ ! $BOOST_ROOT ]] && BOOST_ROOT=$(brew --prefix boost) ;;
esac


if [[ $ALIBUILD_O2_TESTS ]]; then
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

cmake $SOURCEDIR                                              \
  -G Ninja                                                    \
  ${LIBRDKAFKA_REVISION:+-DRDKAFKA_ROOT="${LIBRDKAFKA_ROOT}"} \
  ${GRPC_REVISION:+-DGRPC_ROOT="${GRPC_ROOT}"}                \
  -DCMAKE_INSTALL_PREFIX=$INSTALLROOT                         \
  ${BOOST_REVISION:+-DBOOST_ROOT=$BOOST_ROOT}                 \
  ${LIBGRPC_REVISION:--DO2_MONITORING_CONTROL_ENABLE=0}       \
  ${LIBRDKAFKA_REVISION:--DO2_MONITORING_KAFKA_ENABLE=0}      \
  ${PROTOBUF_ROOT:+-DPROTOBUF_ROOT=$PROTOBUF_ROOT}            \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}

cmake --build . -- ${JOBS+-j $JOBS} install

if [[ $ALIBUILD_O2_TESTS ]]; then
  ctest --output-on-failure
fi

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib --root > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
