package: CMake
version: "%(tag_basename)s"
tag: "v3.5.2"
source: https://github.com/Kitware/CMake
build_requires:
 - "GCC-Toolchain:(?!osx)"
prefer_system: .*
prefer_system_check: |
  which cmake && case `cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3 | head -n1` in [0-2]*|3.[0-4].*|3.5.[0-1]) exit 1 ;; esac
---
#!/bin/bash -e

echo "Building ALICE CMake. To avoid this install at least CMake 3.5.2."

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
