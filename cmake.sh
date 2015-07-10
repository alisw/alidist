package: cmake
version: v2.8.11
source: https://github.com/Kitware/CMake
requires:
  - zlib
tag: v2.8.11
---
#!/bin/sh
cat > build-flags.cmake <<- EOF 
  # Disable Java capabilities; we don't need it and on OS X might miss
        # required /System/Library/Frameworks/JavaVM.framework/Headers/jni.h.
  SET(JNI_H FALSE CACHE BOOL "" FORCE)
  SET(Java_JAVA_EXECUTABLE FALSE CACHE BOOL "" FORCE)
  SET(Java_JAVAC_EXECUTABLE FALSE CACHE BOOL "" FORCE)

  # SL6 with GCC 4.6.1 and LTO requires -ltinfo with -lcurses for link
  # to succeed, but cmake is not smart enough to find it. We don't
  # really need ccmake anyway, so just disable it.
  SET(BUILD_CursesDialog FALSE CACHE BOOL "" FORCE)

  # Use system libraries, not cmake bundled ones.
  SET(CMAKE_USE_SYSTEM_LIBRARY_CURL TRUE CACHE BOOL "" FORCE)
  SET(CMAKE_USE_SYSTEM_LIBRARY_ZLIB TRUE CACHE BOOL "" FORCE)
  SET(CMAKE_USE_SYSTEM_LIBRARY_BZIP2 TRUE CACHE BOOL "" FORCE)
  SET(CMAKE_USE_SYSTEM_LIBRARY_EXPAT TRUE CACHE BOOL "" FORCE)
EOF

$SOURCEDIR/configure --prefix=$INSTALLROOT --init=build-flags.cmake ${JOBS+--parallel=JOBS}

make ${JOBS+-j $JOBS}
make install/strip
