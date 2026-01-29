package: hijing
version: "%(tag_basename)s"
tag: "v1.36.1-alice1"
source: https://github.com/alisw/hijing.git
requires:
  - GCC-Toolchain:(?!osx)
build_requires:
  - CMake
  - alibuild-recipe-tools
  - ninja-fortran
---
#!/bin/sh
cmake ${SOURCEDIR}                           \
      -G Ninja                               \
      -DCMAKE_INSTALL_PREFIX=${INSTALLROOT}

cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

alibuild-generate-module --bin > "$MODULEFILE"
cat >> "$MODULEFILE" <<EOF
# extra environment
setenv HIJING_ROOT \$PKG_ROOT
EOF
