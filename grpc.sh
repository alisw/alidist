package: grpc
version: "%(tag_basename)s"
tag:  v1.15.1-alice1
requires:
  - protobuf
build_requires:
  - "GCC-Toolchain:(?!osx)"
source: https://github.com/alisw/grpc
prefer_system: "(?!slc5)"
prefer_system_check: which grpc_cpp_plugin
incremental_recipe: |
  make ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e

if [[ $PKGVERSION =~ ^v((.+)(-alice[0-9]+)|(.+))$ ]]; then
  # Define a variable with the version number minus the `-alice` suffix.
  # Works also with non-ALICE versions
  REALVERSION=${BASH_REMATCH[2]}
  [[ $REALVERSION ]] || REALVERSION=${BASH_REMATCH[4]}
else
  echo "Invalid version number: $PKGVERSION"
  exit 1
fi

# We need the sources here; do not copy everything by using `--reference` wisely
git clone "$SOURCE0" --reference "$SOURCEDIR" .
git checkout "$GIT_TAG"
git submodule update --init

# gRPC has a custom Makefile which readily breaks with some environment vars,
# better to run it in a clean environment
env -i HOME="$HOME"                             \
       LC_CTYPE="${LC_ALL:-${LC_CTYPE:-$LANG}}" \
       PATH="$PATH"                             \
       USER="$USER"                             \
       LD_LIBRARY_PATH="$LD_LIBRARY_PATH"       \
       make ${JOBS:+-j$JOBS} prefix=$INSTALLROOT

# ldconfig won't work if we're not running make install as root, and that's ok,
# we don't need it
sed -i -e 's/ldconfig/true/' Makefile
make prefix=$INSTALLROOT install

# Add missing symlink. Must be relative, because the directory is moved around
# after the build.  This should normally not be necessary, but it is made
# necessary by the issues linked in the following upstream pull request:
# https://github.com/grpc/grpc/pull/13500 Once the issue gets fixed, it should
# be safe to remove this workaround.
[[ -e $INSTALLROOT/lib/libgrpc++.so.${REALVERSION} ]] || { echo "Library libgrpc++.so.${REALVERSION} not found"; exit 1; }
ln -nfs libgrpc++.so.${REALVERSION} $INSTALLROOT/lib/libgrpc++.so.1

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
module load BASE/1.0
# Our environment
set GRPC_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH \$GRPC_ROOT/bin
prepend-path LD_LIBRARY_PATH \$GRPC_ROOT/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$GRPC_ROOT/lib")
EoF
