package: Millepede-II
version: "%(tag_basename)s"
tag: "V04-17-05"
source: https://gitlab.desy.de/claus.kleinwort/millepede-ii.git
requires:
  - zlib
  - openmp
  - OpenBLAS
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

rsync -av --delete --exclude="**/.git" ${SOURCEDIR}/ .

case $ARCHITECTURE in
    osx*)
    [[ ! $ZLIB_ROOT ]] && ZLIB_ROOT=`brew --prefix zlib` ;;
esac

make pede\
     ${ZLIB_ROOT:+ ZLIB_INCLUDES_DIR=${ZLIB_ROOT}/include ZLIB_LIBS_DIR=${ZLIB_ROOT}/lib}\
     ${OPENBLAS_ROOT:+ SUPPORT_LAPACK64=yes LAPACK64=OPENBLAS LAPACK64_LIBS_DIR=${OPENBLAS_ROOT}/lib LAPACK64_LIB=openblas}
      
rsync -a --delete pede ${INSTALLROOT}/bin/

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module --bin > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
