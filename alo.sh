package: alo
version: "%(commit_hash)s%(defaults_upper)s"
requires:
  - AliRoot
  - O2
  - RapidJSON
build_requires:
  - CMake
source: https://github.com/mrrtf/alo
tag: master
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
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

echo "Build MRRTF alo"

cmake $SOURCEDIR \
    -DCMAKE_INSTALL_PREFIX="$INSTALLROOT" \
    -DALIROOT="$ALIROOT_ROOT" \
    -DROOTSYS="$ROOT_ROOT" \
    -DRAPIDJSON_INCLUDEDIR="$RAPIDJSON_ROOT/include" \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=1

make ${JOBS+-j $JOBS} install

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
module load BASE/1.0 FairRoot/$FAIRROOT_VERSION-$FAIRROOT_REVISION ${DDS_ROOT:+DDS/$DDS_VERSION-$DDS_REVISION} ${GCC_TOOLCHAIN_ROOT:+GCC-Toolchain/$GCC_TOOLCHAIN_VERSION-$GCC_TOOLCHAIN_REVISION} ${VC_VERSION:+Vc/$VC_VERSION-$VC_REVISION} ${ALIROOT_VERSION:+AliRoot/$ALIROOT_VERSION-$ALIROOT_REVISION}
# Our environment
setenv ALO_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$::env(ALO_ROOT)/bin
prepend-path LD_LIBRARY_PATH \$::env(ALO_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(ALO_ROOT)/lib")
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
