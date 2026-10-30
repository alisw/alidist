package: ndmspc
version: "%(tag_basename)s"
tag: "v1.4.0-rc51"
requires:
  - ROOT
  - JAliEn-ROOT
  - ZeroMQ
  - nlohmann_json
#  - arrow
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
#  - "OpenSSL:(?!osx)"
license: GPL-3.0
source: https://gitlab.com/ndmspc/ndmspc.git
incremental_recipe: |
  [[ $ALIBUILD_NDMSPC_TESTS ]] && CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
  cmake --build . -- ${JOBS:+-j$JOBS} install
  mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
---
#!/bin/bash -e
# OpenSSL selection (CMake NDMSPC_OPENSSL, see cmake/modules/FindOpenSSL.cmake):
#   NDMSPC_OPENSSL_MODE=v1      (default) OpenSSL from OPENSSL_ROOT (aliBuild, 1.1)
#   NDMSPC_OPENSSL_MODE=system  ignore OPENSSL_ROOT, use the system OpenSSL >= 3
#   NDMSPC_OPENSSL_MODE=env     use OpenSSL >= 3 from OPENSSL_ROOT
# Changing the mode requires a full rebuild: the incremental_recipe above only runs cmake --build.
case $ARCHITECTURE in
  osx*)
        [[ -n $OPENSSL_ROOT ]] || OPENSSL_ROOT=$(brew --prefix openssl@3)
        # There is no OpenSSL 1.1 in the macOS environment; use the brew 3.x by default.
        [[ -z ${NDMSPC_OPENSSL_MODE:-} ]] && NDMSPC_OPENSSL_MODE=env
  ;;
esac

if [[ $ALIBUILD_NDMSPC_TESTS ]]; then
  # Impose extra errors.
  CXXFLAGS="${CXXFLAGS} -Werror -Wno-error=deprecated-declarations"
fi

OPENSSL_MODE="${NDMSPC_OPENSSL_MODE:-v1}"
case "$OPENSSL_MODE" in
  v1|1.1)
    if [[ -z "${OPENSSL_ROOT:-}" ]]; then
      echo "ERROR: NDMSPC_OPENSSL_MODE=$OPENSSL_MODE needs OPENSSL_ROOT (ROOT provides it through its OpenSSL dependency)" >&2
      exit 1
    fi
    OPENSSL_ARGS=(-DNDMSPC_OPENSSL=1.1)
    ;;
  system|3)
    unset OPENSSL_ROOT
    OPENSSL_ARGS=(-DNDMSPC_OPENSSL=3)
    ;;
  env|prefix)
    if [[ -z "${OPENSSL_ROOT:-}" ]]; then
      echo "ERROR: NDMSPC_OPENSSL_MODE=$OPENSSL_MODE needs OPENSSL_ROOT to point to OpenSSL >= 3" >&2
      exit 1
    fi
    OPENSSL_ARGS=(-DNDMSPC_OPENSSL=env -DOPENSSL_ROOT_DIR="$OPENSSL_ROOT")
    ;;
  *)
    echo "ERROR: unknown NDMSPC_OPENSSL_MODE='$OPENSSL_MODE' (use v1, system or env)" >&2
    exit 1
    ;;
esac

# Version reported by the binaries: nearest git tag plus commits/hash when the source has git
# metadata (aliBuild clones the repository), otherwise the aliBuild package version.
NDMSPC_VERSION_STRING="${PKG_VERSION:-}"
NDMSPC_RELEASE_STRING="${PKG_REVISION:-}"
if [ -d "$SOURCEDIR/.git" ]; then
  GIT_DESC=$(cd "$SOURCEDIR" && { git describe --tags --long 2>/dev/null || git describe --always 2>/dev/null; } || true)
  if [ -n "$GIT_DESC" ]; then
    case "$GIT_DESC" in
      *-*-g*)
        NDMSPC_VERSION_STRING=${GIT_DESC%-*-g*}
        NDMSPC_RELEASE_STRING=${GIT_DESC#"$NDMSPC_VERSION_STRING"-}
        # Exact tag: "<tag>-0-g<hash>" -> show "<tag>-<hash>".
        case "$NDMSPC_RELEASE_STRING" in
          0-g*) NDMSPC_RELEASE_STRING=${NDMSPC_RELEASE_STRING#0-g} ;;
        esac
        ;;
      *)
        NDMSPC_RELEASE_STRING=$GIT_DESC
        ;;
    esac
  fi
fi
NDMSPC_RELEASE_STRING=${NDMSPC_RELEASE_STRING%-dirty}
NDMSPC_VERSION_STRING=${NDMSPC_VERSION_STRING#v}

VERSION_ARGS=()
[ -n "$NDMSPC_VERSION_STRING" ] && VERSION_ARGS+=("-DNDMSPC_VERSION=$NDMSPC_VERSION_STRING")
[ -n "$NDMSPC_RELEASE_STRING" ] && VERSION_ARGS+=("-DNDMSPC_VERSION_RELEASE=$NDMSPC_RELEASE_STRING")

cmake "$SOURCEDIR" "-DCMAKE_INSTALL_PREFIX=$INSTALLROOT"                \
      -G Ninja                                                          \
      ${CMAKE_BUILD_TYPE:+"-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE"}       \
      ${CXXSTD:+"-DCMAKE_CXX_STANDARD=$CXXSTD"}                         \
      -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
      "${OPENSSL_ARGS[@]}" \
      "${VERSION_ARGS[@]}"

cmake --build . -- ${JOBS+-j $JOBS} install

# export compile_commands.json in (taken from o2.sh)
DEVEL_SOURCES="$(readlink $SOURCEDIR || echo $SOURCEDIR)"
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
setenv NDMSPC_RELEASE \$version
setenv NDMSPC_BASEDIR \$::env(BASEDIR)/$PKGNAME
setenv NDMSPC_DIR \$::env(NDMSPC_BASEDIR)/\$::env(NDMSPC_RELEASE)
setenv NDMSPC_MACRO_DIR \$::env(NDMSPC_DIR)/macros
setenv NDMSPC_TUTORIAL_DIR \$::env(NDMSPC_DIR)/tutorial
prepend-path ROOT_DYN_PATH \$PKG_ROOT/lib
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
