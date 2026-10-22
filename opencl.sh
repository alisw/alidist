package: OpenCL
version: "v2026.05.29"
license: Apache-2.0
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
env:
  OpenCL_ROOT: "$OPENCL_ROOT"
---
#!/bin/bash -e
FULLVERSION=${PKGVERSION#v}

for COMPONENT in OpenCL-Headers OpenCL-ICD-Loader; do
  FILENAME=${COMPONENT}-${FULLVERSION}.tar.gz
  if [[ -n $ALIBUILD_O2_FORCE_GPU_BUILDSOURCES ]]; then
    cp "${ALIBUILD_O2_FORCE_GPU_BUILDSOURCES}/${FILENAME}" ./
  else
    curl -fL -o "${FILENAME}" "https://github.com/KhronosGroup/${COMPONENT}/archive/refs/tags/${PKGVERSION}.tar.gz"
  fi
  rm -Rf "${COMPONENT}-${FULLVERSION}"
  tar -zxf "${FILENAME}"
  rm -f "${FILENAME}"
done

# OpenCL C headers
cmake -S "OpenCL-Headers-${FULLVERSION}" -B build-headers -GNinja \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                        \
      -DCMAKE_INSTALL_LIBDIR=lib                                   \
      -DBUILD_TESTING=OFF                                          \
      -DOPENCL_HEADERS_BUILD_TESTING=OFF
cmake --build build-headers --target install

# OpenCL ICD loader, providing libOpenCL.so
cmake -S "OpenCL-ICD-Loader-${FULLVERSION}" -B build-icd-loader -GNinja \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                            \
      -DCMAKE_INSTALL_LIBDIR=lib                                       \
      -DCMAKE_BUILD_TYPE=Release                                       \
      -DCMAKE_PREFIX_PATH="$INSTALLROOT"                               \
      -DOPENCL_ICD_LOADER_HEADERS_DIR="$INSTALLROOT/include"           \
      -DOPENCL_ICD_LOADER_BUILD_SHARED_LIBS=ON                         \
      -DBUILD_TESTING=OFF                                              \
      -DOPENCL_ICD_LOADER_BUILD_TESTING=OFF
cmake --build build-icd-loader --target install ${JOBS:+-- -j$JOBS}

rm -Rf build-headers build-icd-loader "OpenCL-Headers-${FULLVERSION}" "OpenCL-ICD-Loader-${FULLVERSION}"

# Modulefile
MODULEDIR="${INSTALLROOT}/etc/modulefiles"
MODULEFILE="${MODULEDIR}/${PKGNAME}"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib --cmake > "$MODULEFILE"
