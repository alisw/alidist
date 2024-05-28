package: STARlight
version: "20240714"
tag: 9980f5d
requires:
  - HepMC3
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/STARlightsim/STARlight.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE                   \
                 -DENABLE_HEPMC3=ON                        \
                 -DHepMC3_DIR="$HEPMC3_ROOT"
cmake --build . -- ${JOBS:+-j$JOBS}
mkdir -p $INSTALLROOT/bin
cp ./starlight $INSTALLROOT/bin/.
mkdir -p $INSTALLROOT/lib
cp ./libStarlib.a $INSTALLROOT/lib/.
cp -r $SOURCEDIR/config $INSTALLROOT/.
cp -r $SOURCEDIR/include $INSTALLROOT/.

#ConfigFile
cat << EOF > $INSTALLROOT/bin/starlight-config
echo $INSTALLROOT
EOF
chmod +x $INSTALLROOT/bin/starlight-config

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
