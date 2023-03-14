package: libjalienws
version: "%(tag_basename)s"
tag: "0.1.5"
source: https://gitlab.cern.ch/jalien/libjalienws.git
requires:
  - libwebsockets
  - libjalienO2
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
  - "Xcode:(osx.*)"
---
#!/bin/bash -e

rsync -a --exclude '**/.git' --delete "${SOURCEDIR}/" "${BUILDDIR}"

cmake "${BUILDDIR}"                                          \
      -DCMAKE_INSTALL_PREFIX="${INSTALLROOT}"
make ${JOBS:+-j $JOBS} VERBOSE=1 install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > "etc/modulefiles/${PKGNAME}"

cat >> "etc/modulefiles/${PKGNAME}" <<EoF
setenv LIBJALIENWS_ROOT \$PKG_ROOT
EoF

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"
