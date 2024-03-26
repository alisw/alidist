package: STARlight
version: "%(tag_basename)s"
tag: r313-c
build_requires:
  - CMake
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/alisw/STARlight.git
---
#!/bin/bash -ex
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT       \
                 ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
                 -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE      \
                 -DCMAKE_SKIP_RPATH=TRUE
cmake --build . -- ${JOBS:+-j$JOBS}
mkdir -p $INSTALLROOT/bin
cp ./starlight $INSTALLROOT/bin/.
mkdir -p $INSTALLROOT/lib
cp ./libStarlib.a $INSTALLROOT/lib/.
cp -r $SOURCEDIR/config $INSTALLROOT/.
cp -r $SOURCEDIR/include $INSTALLROOT/.
cp -r $SOURCEDIR/HepMC $INSTALLROOT/.

#ConfigFile
cat << EOF > $INSTALLROOT/bin/starlight-config
echo $INSTALLROOT
EOF
chmod +x $INSTALLROOT/bin/starlight-config

#ModuleFile
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
module load BASE/1.0                                                            

# STARlight environment:
set STARLIGHT_ROOT \$::env(BASEDIR)/$PKGNAME/\$version

prepend-path PATH \$STARLIGHT_ROOT/bin
prepend-path LD_LIBRARY_PATH \$STARLIGHT_ROOT/lib

EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
