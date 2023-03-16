package: libpng
version: v1.6.34
requires:
  - zlib
build_requires:
  - CMake
  - alibuild-recipe-tools
source: https://github.com/alisw/libpng
prefer_system: (?!slc5)
prefer_system_check: |
  #!/bin/bash -e
  # shellcheck disable=SC2046
  c++ -xc++ - $(libpng-config --cflags) -c -M <<< "#include <png.h>" 2>&1 || { printf "libpng was not found.
  * On RHEL-compatible systems you probably need: libpng libpng-devel
  * On Ubuntu-compatible systems you probably need: libpng12-0 libpng12-dev"; exit 1; }
---
#!/bin/bash -e

rsync -a "${SOURCEDIR}/" .
cmake .                                          \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALLROOT}" \
    -DBUILD_SHARED_LIBS=YES                      \
    ${ZLIB_ROOT:+-DZLIB_ROOT:PATH=$ZLIB_ROOT}    \
    -DCMAKE_SKIP_RPATH=YES                       \
    -DSKIP_INSTALL_FILES=1                       \
    -DCMAKE_INSTALL_LIBDIR=lib
make ${JOBS:+-j $JOBS}
make install

# ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --lib --bin > "etc/modulefiles/${PKGNAME}"

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"
