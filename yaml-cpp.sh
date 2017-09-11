package: yaml-cpp
version: "v0.5.2"
source: https://github.com/jbeder/yaml-cpp
tag: release-0.5.2
requires:
  - boost
build_requires:
  - CMake
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"yaml-cpp/yaml.h\"\n" | gcc -I`brew --prefix yaml-cpp`/include -I`brew --prefix boost`/include -xc++ - -c -o /dev/null
---
#!/bin/sh
case $ARCHITECTURE in
  slc5*) sed -i -e 's/-Wno-c99-extensions //' $SOURCEDIR/test/CMakeLists.txt ;;
  osx*) [[ $BOOST_ROOT ]] || BOOST_ROOT=`brew --prefix boost` ;;
  *) ;;
esac

cmake \
  ${C_COMPILER:+-DCMAKE_C_COMPILER=$C_COMPILER}          \
  ${CXX_COMPILER:+-DCMAKE_CXX_COMPILER=$CXX_COMPILER}    \
  -DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE                   \
  -DCMAKE_INSTALL_PREFIX:PATH="$INSTALLROOT"             \
  -DBUILD_SHARED_LIBS=YES                                \
  ${BOOST_ROOT:+-DBOOST_ROOT:PATH="$BOOST_ROOT"}         \
  ${BOOST_ROOT:+-DBoost_DIR:PATH="$BOOST_ROOT"}          \
  ${BOOST_ROOT:+-DBoost_INCLUDE_DIR:PATH="$BOOST_ROOT/include"}  \
  -DCMAKE_SKIP_RPATH=YES                                 \
  -DSKIP_INSTALL_FILES=1                                 \
  $SOURCEDIR

make ${JOBS+-j $JOBS} install

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
module load BASE/1.0 ${BOOST_VERSION:+boost/$BOOST_VERSION-$BOOST_REVISION}
# Our environment
setenv YAMLCPP \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path LD_LIBRARY_PATH \$::env(YAMLCPP)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(YAMLCPP)/lib")
EoF
