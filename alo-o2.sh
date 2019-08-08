package: alo-o2
version: "%(commit_hash)s"
tag: master
requires:
  - googlebenchmark
  - O2
  - RapidJSON
  - yaml-cpp
build_requires:
  - CMake
  - ms_gsl
source: https://github.com/mrrtf/alo
incremental_recipe: |
  cmake --build . -- ${JOBS+-j $JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
  # install the compilation database so that we can post-check the code
  cp ${BUILDDIR}/compile_commands.json ${INSTALLROOT}
  
  DEVEL_SOURCES="$(readlink $SOURCEDIR || echo $SOURCEDIR)"
  # This really means we are in development mode. We need to make sure we
  # use the real path for sources in this case. We also copy the
  # compile_commands.json file so that IDEs can make use of it directly, this
  # is a departure from our "no changes in sourcecode" policy, but for a good reason
  # and in any case the file is in gitignore.
  if [[ "$DEVEL_SOURCES" != "$SOURCEDIR" ]]; then
          perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
          ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
  fi
---
#!/bin/bash

cmake $SOURCEDIR \
    ${CMAKE_GENERATOR:+-G "$CMAKE_GENERATOR"} \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DO2="$O2_ROOT" \
    -DROOTSYS="$ROOT_ROOT" \
    -DRAPIDJSON_INCLUDEDIR="$RAPIDJSON_ROOT/include" \
    -DMS_GSL_INCLUDE_DIR=$MS_GSL_ROOT/include \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}

cmake --build . -- ${JOBS+-j $JOBS} install

# install the compilation database so that we can post-check the code
cp compile_commands.json ${INSTALLROOT}

DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
# This really means we are in development mode. We need to make sure we
# use the real path for sources in this case. We also copy the
# compile_commands.json file so that IDEs can make use of it directly, this
# is a departure from our "no changes in sourcecode" policy, but for a good reason
# and in any case the file is in gitignore.
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
fi

# Modulefile
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
module load BASE/1.0 O2/$O2_VERSION-$O2_REVISION
# Our environment
setenv ALO_O2_ROOT \$::env(BASEDIR)/$PKGNAME/\$version

prepend-path PATH \$::env(ALO_O2_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALO_O2_ROOT)/lib
EoF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
