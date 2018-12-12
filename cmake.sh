package: CMake
version: "%(tag_basename)s"
tag: "v3.13.1"
source: https://github.com/Kitware/CMake
build_requires:
 - "GCC-Toolchain:(?!osx)"
prefer_system: .*
prefer_system_check: |
  verge() { [[  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]]; }
  type cmake && verge 3.13.1 `cmake --version | sed -e 's/.* //' | cut -d. -f1,2,3`
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

# OpenSSL is problematic
set(CMAKE_USE_OPENSSL FALSE CACHE BOOL "" FORCE)
EOF

$SOURCEDIR/bootstrap --prefix=$INSTALLROOT \
                     --init=build-flags.cmake \
                     ${JOBS:+--parallel=$JOBS}
make ${JOBS+-j $JOBS}
make install/strip

mkdir -p etc/modulefiles
cat > etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 \\
       ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION}
# Our environment
setenv CMAKE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(CMAKE_ROOT)/bin
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
