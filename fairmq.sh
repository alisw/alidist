package: FairMQ
version: "%(tag_basename)s"
tag: "v1.9.0"
source: https://github.com/FairRootGroup/FairMQ
requires:
  - boost
  - FairLogger
  - ZeroMQ
build_requires:
  - alibuild-recipe-tools
  - CMake
  - FairCMakeModules
  - "GCC-Toolchain:(?!osx)"
  - ninja
prepend_path:
  ROOT_INCLUDE_PATH:
    - "${FAIRMQ_ROOT}/include"
    - "${FAIRMQ_ROOT}/include/fairmq"
incremental_recipe: |
  #!/bin/bash -e
  cmake --build . ${JOBS:+-j$JOBS}
  cmake --install .
  MODULEDIR="etc/modulefiles"
  mkdir -p "${INSTALLROOT}/${MODULEDIR}"
  rsync -a --delete "${MODULEDIR}/" "${INSTALLROOT}/${MODULEDIR}"
---
#!/bin/bash -e

case ${ARCHITECTURE} in
  osx*)
    [[ -n ${BOOST_ROOT}  ]] ||  BOOST_ROOT=$(brew --prefix boost)
    [[ -n ${ZEROMQ_ROOT} ]] || ZEROMQ_ROOT=$(brew --prefix zeromq)
  ;;
esac

cmake "${SOURCEDIR}" -DCMAKE_INSTALL_PREFIX="${INSTALLROOT}"      \
      -GNinja                                                     \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=${CXXSTD}}                   \
      ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=${CXX_COMPILER}}       \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}} \
      -DCMAKE_INSTALL_LIBDIR=lib                                  \
      -DDISABLE_COLOR=ON                                          \
      -DBUILD_EXAMPLES=OFF                                        \
      -DBUILD_TESTING=OFF
# NOTE: FairMQ examples must always be built in RPMs as they are
#       used for AliECS integration testing. Please do not disable
#       them.

cmake --build . ${JOBS:+-j${JOBS}}

if [[ -n ${ALIBUILD_FAIRMQ_TESTS} ]]; then
  ctest --output-on-failure --schedule-random ${JOBS:+-j${JOBS}}
fi

cmake --install .

# ModuleFile
MODULEDIR="etc/modulefiles"
mkdir -p "${MODULEDIR}"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
alibuild-generate-module --bin --lib > "${MODULEFILE}"
cat << EOF >> "${MODULEFILE}"
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include/fairmq
EOF
mkdir -p "${INSTALLROOT}/${MODULEDIR}"
rsync -a --delete "${MODULEDIR}/" "${INSTALLROOT}/${MODULEDIR}"
