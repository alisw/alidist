package: gl2ps
version: v1.4.2
tag: "gl2ps_1_4_2"
source: https://gitlab.onelab.info/gl2ps/gl2ps.git
license: LGPLv2+
requires:
  - "opengl:(?!osx)"
build_requires:
  - CMake
  - ninja
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prefer_system: "(?!slc5)"
prefer_system_check: |
  GL2PS_PREFIX=$(brew --prefix --installed gl2ps 2>/dev/null)
  if ! printf "#include <gl2ps.h>\n" | cc -xc - ${GL2PS_PREFIX:+-I$GL2PS_PREFIX/include} -c -M 2>&1; then
    printf "gl2ps was not found.\n"
    printf " * On RHEL-compatible systems you probably need: gl2ps gl2ps-devel (from EPEL)\n"
    printf " * On Ubuntu-compatible systems you probably need: libgl2ps-dev\n"
    printf " * On macOS you probably need: brew install gl2ps\n"
    exit 1
  fi
---
#!/bin/bash -e
# ENABLE_PNG / ENABLE_ZLIB are off for the same reason ROOT turns them off in
# its own builtins/gl2ps: they only add optional compression of the PostScript
# output, and leaving them on would drag libpng and zlib into gl2ps' link line.
# GLUT and LaTeX are only used for the example programs and the manual.
# gl2ps still declares cmake_minimum_required(VERSION 2.8), which CMake 4
# rejects outright without CMAKE_POLICY_VERSION_MINIMUM.
cmake "$SOURCEDIR"                              \
    -G Ninja                                    \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"       \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5          \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON        \
    -DCMAKE_INSTALL_NAME_DIR="$INSTALLROOT/lib" \
    -DCMAKE_DISABLE_FIND_PACKAGE_GLUT=ON        \
    -DCMAKE_DISABLE_FIND_PACKAGE_LATEX=ON       \
    -DENABLE_PNG=OFF                            \
    -DENABLE_ZLIB=OFF                           \
    -DLIB_SUFFIX=
cmake --build . -- ${JOBS:+-j$JOBS} install

# gl2ps wraps its whole add_library()/install(TARGETS) block in if(OPENGL_FOUND)
# and says nothing when it is false: without this check a missing libGL would
# yield a package holding only gl2ps.h, and the failure would surface much
# later, as ROOT not finding gl2ps.
ls "$INSTALLROOT"/lib/libgl2ps.* > /dev/null

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEFILE"
