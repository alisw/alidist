package: zlib
version: "%(tag_basename)s"
tag: v1.3.1
license: Zlib
source: https://github.com/madler/zlib
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - alibuild-recipe-tools
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <zlib.h>\n" | cc -xc - -c -M 2>&1
---
rsync -a --chmod=ug=rwX --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

./configure --prefix="$INSTALLROOT"

make ${JOBS+-j $JOBS}
make install

# Upstream ships no CMake package config, so config-mode find_package(ZLIB) walks
# past us to the system one -- which on EL10 (zlib-ng-compat-devel) references a
# libz.a that only ships in CRB, and errors out when it is absent.
alibuild-generate-cmake-config --name ZLIB --lib z --static-target ZLIB::zlibstatic

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > "$MODULEFILE"
