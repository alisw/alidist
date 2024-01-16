package: ndmspc
version: "%(tag_basename)s"
tag: "v0.0.1"
requires:
  - ROOT
build_requires:
  - "Clang:(?!osx)"
  - CMake
  - alibuild-recipe-tools
source: https://gitlab.com/ndmspc/ndmspc.git
incremental_recipe: |
  [[ $ALIBUILD_NDMSPC_TESTS ]] && CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/sh

if [[ $ALIBUILD_NDMSPC_TESTS ]]; then
  # Impose extra errors.
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi
cmake --version

# When O2 is built against Gandiva (from Arrow), then we need to use
# -DLLVM_ROOT=$CLANG_ROOT, since O2's CMake calls into Gandiva's
# -CMake, which requires it.
cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"
cmake --build . -- ${JOBS+-j $JOBS} install

# export compile_commands.json in (taken from o2.sh)
DEVEL_SOURCES="`readlink $SOURCEDIR || echo $SOURCEDIR`"
if [ "$DEVEL_SOURCES" != "$SOURCEDIR" ]; then
  perl -p -i -e "s|$SOURCEDIR|$DEVEL_SOURCES|" compile_commands.json
  ln -sf $BUILDDIR/compile_commands.json $DEVEL_SOURCES/compile_commands.json
fi

# Modulefile
mkdir -p etc/modulefiles
MODULEFILE="etc/modulefiles/$PKGNAME"
alibuild-generate-module --bin --lib > "$MODULEFILE"
cat >> "$MODULEFILE" <<EoF
# Our environment
set NDMSPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv NDMSPC_ROOT \$NDMSPC_ROOT
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
