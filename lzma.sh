package: lzma
version: "%(tag_basename)s"
tag: "v5.8.4"
license: 0BSD
source: https://github.com/tukaani-project/xz
build_requires:
  - CMake
  - ninja
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prefer_system: "(?!slc5)"
prefer_system_check: |
  XZ_PREFIX=$(brew --prefix --installed xz 2>/dev/null)
  if ! printf "#include <lzma.h>\n" | cc -xc - ${XZ_PREFIX:+-I$XZ_PREFIX/include} -c -M 2>&1; then
    printf "liblzma was not found.\n"
    printf " * On RHEL-compatible systems you probably need: xz-libs xz-devel\n"
    printf " * On Ubuntu-compatible systems you probably need: liblzma5 liblzma-dev\n"
    printf " * On macOS you probably need: brew install xz\n"
    exit 1
  fi
---
#!/bin/bash -e
# xz ships both autotools and CMake; CMake avoids needing autoconf, libtool and
# autopoint on the builders, which ./autogen.sh would pull in.
#
# BUILD_SHARED_LIBS picks one flavour rather than building both, so we configure
# twice. ROOT links against the shared liblzma -- root.sh passes
# -DLIBLZMA_LIBRARY=$LZMA_ROOT/lib/liblzma.<so|dylib> -- while the static
# library is what this recipe used to install exclusively, so it is kept for
# anything still expecting it. The static pass builds the library alone; the
# shared pass goes last so the tools, pkg-config and CMake package files it
# installs describe the shared build.
XZ_COMMON_FLAGS=(
  -G Ninja
  -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"
  -DCMAKE_INSTALL_LIBDIR=lib
  -DCMAKE_POSITION_INDEPENDENT_CODE=ON
  -DCMAKE_INSTALL_NAME_DIR="$INSTALLROOT/lib"
  -DXZ_NLS=OFF
  -DXZ_DOC=OFF
)

cmake -S "$SOURCEDIR" -B build-static "${XZ_COMMON_FLAGS[@]}" \
      -DBUILD_SHARED_LIBS=OFF                                 \
      -DXZ_TOOL_XZ=OFF                                        \
      -DXZ_TOOL_XZDEC=OFF                                     \
      -DXZ_TOOL_LZMADEC=OFF                                   \
      -DXZ_TOOL_LZMAINFO=OFF                                  \
      -DXZ_TOOL_SCRIPTS=OFF
cmake --build build-static -- ${JOBS:+-j$JOBS} install

cmake -S "$SOURCEDIR" -B build-shared "${XZ_COMMON_FLAGS[@]}" \
      -DBUILD_SHARED_LIBS=ON
cmake --build build-shared -- ${JOBS:+-j$JOBS} install

# Both consumers in alidist (ROOT and Boost) name the libraries by path, so a
# build that quietly produced only one of them would fail much later.
ls "$INSTALLROOT"/lib/liblzma.a > /dev/null
case $ARCHITECTURE in
  osx*) ls "$INSTALLROOT"/lib/liblzma.dylib > /dev/null ;;
  *)    ls "$INSTALLROOT"/lib/liblzma.so > /dev/null ;;
esac

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
$(alibuild-generate-module --bin --lib)
# Compatibility with recipes looking for \$LZMA_ROOT at runtime
setenv LZMA_ROOT \$PKG_ROOT
EoF
