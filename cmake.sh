package: CMake
version: v2.8.12
tag: v2.8.12
source: https://github.com/Kitware/CMake
requires:
  - zlib
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

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 zlib/$ZLIB_VERSION-$ZLIB_REVISION
# Our environment
prepend-path PATH \$::env(BASEDIR)/$PKGNAME/\$version/bin
EoF
