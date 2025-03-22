package: CMake
version: "%(tag_basename)s"
tag: "v3.28.1"
source: https://github.com/Kitware/CMake
requires:
  - "OpenSSL:(?!osx)"
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - make
  - alibuild-recipe-tools
prefer_system: osx.*
prefer_system_check: |
  verge() { [[  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]]; }
  echo alibuild_system_replace: cmake"$(cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3)"
  type cmake && verge 3.28.1 $(cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3)
prefer_system_replacement_specs:
  "cmake.*":
    env:
      CMAKE_VERSION: ""
---
#!/bin/bash -e

cat > build-flags.cmake <<- EOF
# Disable Java capabilities; we don't need it and on OS X might miss the
# required /System/Library/Frameworks/JavaVM.framework/Headers/jni.h.
SET(JNI_H FALSE CACHE BOOL "" FORCE)
SET(Java_JAVA_EXECUTABLE FALSE CACHE BOOL "" FORCE)
SET(Java_JAVAC_EXECUTABLE FALSE CACHE BOOL "" FORCE)

# SL6 with GCC 4.6.1 and LTO requires -ltinfo with -lcurses for link to succeed,
# but cmake is not smart enough to find it. We do not really need ccmake anyway,
# so just disable it.
SET(BUILD_CursesDialog FALSE CACHE BOOL "" FORCE)
EOF

$SOURCEDIR/bootstrap --prefix=$INSTALLROOT \
                     --init=build-flags.cmake \
                     ${JOBS:+--parallel=$JOBS}
make ${JOBS+-j $JOBS}
make install/strip


mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
