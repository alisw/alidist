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

# Set the environment variables CC and CXX if a compiler is defined in the defaults file
# In case CC and CXX are defined the corresponding compilers are used during compilation
[[ -z "$CXX_COMPILER" ]] || export CXX=$CXX_COMPILER
[[ -z "$C_COMPILER" ]] || export CC=$C_COMPILER

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
