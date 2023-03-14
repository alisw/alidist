package: libjalienO2
version: "%(tag_basename)s"
tag: "0.1.4"
source: https://gitlab.cern.ch/jalien/libjalieno2.git
requires:
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - AliEn-CAs
build_requires:
  - CMake
  - alibuild-recipe-tools
  - "GCC-Toolchain:(?!osx)"
  - "Xcode:(osx.*)"
---
#!/bin/bash -e

if [[ $ARCHITECTURE = osx* ]]; then
  OPENSSL_ROOT=$(brew --prefix openssl@1.1)
fi

cmake "${SOURCEDIR}"                                                   \
      -DOPENSSL_ROOT_DIR="${OPENSSL_ROOT}"                             \
      -DCMAKE_INSTALL_PREFIX="${INSTALLROOT}"
make ${JOBS:+-j $JOBS} install

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --lib > "etc/modulefiles/${PKGNAME}"

mkdir -p "${INSTALLROOT}/etc/modulefiles"
rsync -a --delete etc/modulefiles/ "${INSTALLROOT}/etc/modulefiles"
