package: CMake
version: "%(tag_basename)s"
tag: "v3.31.6"
source: https://github.com/Kitware/CMake
requires:
  - "OpenSSL:(?!osx)"
  - "GCC-Toolchain:(?!osx)"
  - zlib
  - curl
build_requires:
  - make
  - alibuild-recipe-tools
prefer_system: osx.*
prefer_system_check: |
  verge() { [[  "$1" = "$(echo -e "$1\n$2" | sort -V | head -n1)" ]]; }
  verle() { [[  "$1" = "$(echo -e "$1\n$2" | sort -V -r | head -n1)" ]]; }
  current_version=$(cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3)
  echo alibuild_system_replace: cmake"$current_version"
  type cmake && verge 3.28.1 $current_version && verle 3.99.99 $current_version
prefer_system_replacement_specs:
  "cmake.*":
    env:
      CMAKE_VERSION: ""
---
#!/bin/bash -e
SONAME=so
case $ARCHITECTURE in
  osx*) SONAME=dylib ;;
esac

cat > build-flags.cmake <<- EOF
# Disable Java capabilities; we don't need it and on OS X might miss the
# required /System/Library/Frameworks/JavaVM.framework/Headers/jni.h.
SET(JNI_H FALSE CACHE BOOL "" FORCE)
SET(Java_JAVA_EXECUTABLE FALSE CACHE BOOL "" FORCE)
SET(Java_JAVAC_EXECUTABLE FALSE CACHE BOOL "" FORCE)

SET(ZLIB_LIBRARY $ZLIB_ROOT/lib/libz.$SONAME)
SET(ZLIB_INCLUDE_DIR $ZLIB_ROOT/include)

SET(CURL_LIBRARY $CURL_ROOT/lib/libcurl.$SONAME)
SET(CURL_INCLUDE_DIR $CURL_ROOT/include)
SET(BUILD_TESTING OFF)

# SL6 with GCC 4.6.1 and LTO requires -ltinfo with -lcurses for link to succeed,
# but cmake is not smart enough to find it. We do not really need ccmake anyway,
# so just disable it.
SET(BUILD_CursesDialog FALSE CACHE BOOL "" FORCE)
EOF

rsync -a --chmod=ugo=rwX --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

./bootstrap --prefix=$INSTALLROOT \
                     ${ZLIB_ROOT:+--no-system-zlib} \
                     ${CURL_ROOT:+--no-system-curl} \
                     --init=build-flags.cmake \
                     ${JOBS:+--parallel=$JOBS}
make ${JOBS+-j $JOBS}
make install/strip


mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
