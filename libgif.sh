package: libgif
version: "%(tag_basename)s"
tag: "6.1.3"
source: https://git.code.sf.net/p/giflib/code
license: MIT
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prefer_system: "(?!slc5)"
prefer_system_check: |
  GIFLIB_PREFIX=$(brew --prefix --installed giflib 2>/dev/null)
  if ! printf "#include <gif_lib.h>\n" | cc -xc - ${GIFLIB_PREFIX:+-I$GIFLIB_PREFIX/include} -c -M 2>&1; then
    printf "giflib was not found.\n"
    printf " * On RHEL-compatible systems you probably need: giflib giflib-devel\n"
    printf " * On Ubuntu-compatible systems you probably need: libgif-dev\n"
    printf " * On macOS you probably need: brew install giflib\n"
    exit 1
  fi
---
#!/bin/bash -e
# giflib ships a hand-written Makefile which builds in the source directory.
rsync -a --chmod=ug=rwX --delete --exclude '**/.git' --delete-excluded "$SOURCEDIR/" ./

# Build libgif only. The "all" target also builds the utilities and, on Linux,
# runs "make -C doc", which needs xmlto and asciidoc; "shared-lib"/"static-lib"
# additionally build libutil, the helper library for those utilities, which
# does not link on macOS because upstream leaves libgif out of its link line.
# Nothing installs libutil anyway. For the same reason we install the
# individual targets rather than "install", which pulls in man pages and docs.
make ${JOBS:+-j $JOBS} libgif.a

case $ARCHITECTURE in
  osx*)
    # The objects are built by now, so this only links the dylib. giflib's
    # Darwin link line ignores LDFLAGS and passes no -install_name, leaving a
    # bare "libgif.dylib" the loader cannot resolve from elsewhere; there is
    # also no header padding, so install_name_tool cannot fix it afterwards.
    # Inject the install name through CFLAGS instead, which that line does use.
    LIBVER=$(awk -F= '/^LIBMAJOR=/{a=$2} /^LIBMINOR=/{b=$2} /^LIBPOINT=/{c=$2} END{print a"."b"."c}' Makefile)
    make libgif.dylib CFLAGS="$CFLAGS -Wl,-install_name,$INSTALLROOT/lib/libgif.$LIBVER.dylib"
  ;;
  *)
    make libgif.so
  ;;
esac

make PREFIX="$INSTALLROOT" install-include install-lib

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEFILE"
