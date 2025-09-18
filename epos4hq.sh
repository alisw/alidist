package: EPOS4HQ
version: "%(tag_basename)s"
tag: "v1.0hq-alice3"
source: https://github.com/alisw/EPOS4.git
requires:
  - ROOT
  - fastjet
  - HepMC3
  - alibuild-recipe-tools
env:
  EPO4HQVSN: "1.0"
---
#!/bin/bash -ex

export CC=gcc
export CXX=g++
export FC=gfortran
export COP=HQ

export LIBRARY_PATH="$LD_LIBRARY_PATH"
cmake -S ${SOURCEDIR} -DCMAKE_INSTALL_PREFIX=${INSTALLROOT} \
          -DCOMPILE_OPTION=${COP} -DCMAKE_BUILD_TYPE=Release \
          -DFASTSYS=$FASTJET \
          -DCMAKE_INSTALL_MESSAGE=LAZY
cmake --build . -- ${JOBS:+-j $JOBS}
cmake --install .
if [[ $ALIBUILD_O2_TESTS ]]; then
  ctest --test-dir . --verbose
fi

rsync -a \
      --exclude='**/CMakeModules' \
      --exclude=CMakeLists.txt \
      --exclude='**/.git' \
      --exclude=*.h \
      --exclude=*.c \
      --exclude=*.cpp \
      --exclude=*.f \
      $SOURCEDIR/ $INSTALLROOT/

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib --bin >$MODULEFILE
cat >> "$MODULEFILE" <<EoF
setenv EPOS4HQ_ROOT \$PKG_ROOT
setenv EPO4HQVSN 1.0
# Final slash is required by EPOS, please leave it be
setenv EPO4HQ \$PKG_ROOT/
prepend-path PATH \$::env(EPO4HQ)bin
setenv OPT ./
setenv HTO ./
setenv CHK ./
EoF
