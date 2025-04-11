package: EPOS4
version: "%(tag_basename)s"
tag: "v4.0.3-alice1"
source: https://github.com/alisw/EPOS4.git
requires:
  - ROOT
  - fastjet
  - HepMC3
---
#!/bin/bash -ex

export EPO4VSN=${PKGVERSION}

# The following two variables *must* have a trailing slash! EPOS installation
# will make a mess otherwise.
export EPO4=$PWD/
export BUILD_DIR=${EPO4}build
export CC=gcc
export CXX=g++
export FC=gfortran
export COP=BASIC

rsync -a --exclude='**/.git' --delete ${SOURCEDIR}/ .

# patch few CMakeFiles
find ./ -name "CM*.txt" -exec sed -i -e 's/-m64//' {} ';' # not platform independent
find ./ -name "CM*.txt" -exec sed -i -e 's/-fPIC//' {} ';' # not needed and clashes with mcmodel=large on AARCH64

export LIBRARY_PATH="$LD_LIBRARY_PATH"
cmake -S $EPO4 -B $BUILD_DIR -DCMAKE_INSTALL_PREFIX=${EPO4} \
          -DCOMPILE_OPTION=${COP} -DCMAKE_BUILD_TYPE=Release \
          -DFASTSYS=$FASTJET \
          -DCMAKE_INSTALL_MESSAGE=LAZY
cmake --build $BUILD_DIR -j8
cmake --install $BUILD_DIR
ctest --test-dir $BUILD_DIR --verbose

# "Install"
INST_SUBROOT=$INSTALLROOT/epos4
mkdir -p $INST_SUBROOT 
rsync -a \
      --exclude='**/CMakeModules' \
      --exclude=CMakeLists.txt \
      --exclude='**/.git' \
      --exclude=*.h \
      --exclude=*.c \
      --exclude=*.cpp \
      --exclude=*.f \
      ./ $INST_SUBROOT/
chmod u+x $INST_SUBROOT/bin/epos
find $INSTALLROOT -type d -empty -exec rmdir '{}' \; > /dev/null 2>&1 || true
[ -d "$INST_SUBROOT" ]

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
module load BASE/1.0 ROOT/$ROOT_VERSION-$ROOT_REVISION fastjet/$FASTJET_VERSION-$FASTJET_REVISION HepMC3/$HEPMC3_VERSION-$HEPMC3_REVISION
# Our environment
set EPOS4_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv EPOS4_ROOT \$EPOS4_ROOT
setenv EPO4VSN 4.0.3
# Final slash is required by EPOS, please leave it be
setenv EPO4 \$::env(EPOS4_ROOT)/epos4/
prepend-path PATH \$::env(EPO4)bin
setenv OPT ./
setenv HTO ./
setenv CHK ./
EoF
