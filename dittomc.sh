package: DittoMC
version: "%(tag_basename)s"
tag: v1.0.0
requires:
  - ROOT
  - pythia
license: GPL-3.0
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - CMake
  - ninja
  - alibuild-recipe-tools
source: https://github.com/njacazio/DittoMC.git
---
#!/bin/bash -e

cmake "$SOURCEDIR" \
      -G Ninja \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DPYTHIA_ROOT="$PYTHIA_ROOT"

cmake --build . --target install ${JOBS:+-- -j$JOBS}

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --lib --cmake > "$MODULEFILE"
cat <<'EOF' >> "$MODULEFILE"
setenv DITTOMC_ROOT \$PKG_ROOT
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include
prepend-path ROOT_INCLUDE_PATH $PKG_ROOT/include/Ditto
EOF
