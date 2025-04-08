package: STARlight
version: "20241115"
tag: b845eb773cd5be1ed2286e236e575519d08fed4d
requires:
  - DPMJET
  - HepMC3
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
source: https://github.com/STARlightsim/STARlight.git
---
#!/bin/bash -ex
export DPMJET_DIR=$DPMJET_ROOT
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE                   \
                 -DENABLE_HEPMC3=ON                        \
		 -DENABLE_DPMJET=ON                        \
                 -DCMAKE_EXPORT_COMPILE_COMMANDS=ON        \
                 -DBUILD_SHARED_LIB=ON                     \
                 -DCMAKE_INSTALL_LIBDIR=lib                \
                 -DHepMC3_DIR="$HEPMC3_ROOT"		\
		 -DDPMJET_DIR="$DPMJET_ROOT"

cmake --build . -- ${JOBS:+-j$JOBS} install
cp libDpmJetLib.so $INSTALLROOT/lib
cp -r $SOURCEDIR/config $INSTALLROOT/.
cp -r $SOURCEDIR/include $INSTALLROOT/.

# We need to fix the installation of STARlight, in particular
# header files. They define global macros which clash with other code when
# included in ROOT macros.
sed -i 's/printInfo/starlight_printInfo/' ${INSTALLROOT}/include/*.h
sed -i 's/printWarn/starlight_printWarn/' ${INSTALLROOT}/include/*.h
sed -i 's/printErr/starlight_printErr/' ${INSTALLROOT}/include/*.h

#ConfigFile
cat << EOF > $INSTALLROOT/bin/starlight-config
echo $INSTALLROOT
EOF
chmod +x $INSTALLROOT/bin/starlight-config

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
cat >> "$MODULEFILE" <<EOF
# extra environment
# we define this so that the starlight installation can be found/queried
setenv ${PKGNAME}_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
# we purposely are not adding to ROOT_INCLUDE_PATH
# to avoid making that search path to long. Users can do
# this themsevles in the ROOT macro (just-in-time) via ${PKGNAME}_ROOT.
# prepend-path ROOT_INCLUDE_PATH \$${PKGNAME}_ROOT/include/
EOF
