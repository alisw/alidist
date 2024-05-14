package: Toolchain
version: "%(tag_basename)s"
tag: v1.0
build_requires:
  - "GCC-Toolchain:(?!osx)"
---
mkdir -p $INSTALLROOT/etc/modulefiles
cp $GCC_TOOLCHAIN_ROOT/etc/modulefiles/GCC-Toolchain $INSTALLROOT/etc/modulefiles/GCC-${GCC_TOOLCHAIN_VERSION//-*}
ln -sf GCC-${GCC_TOOLCHAIN_VERSION//-*} $INSTALLROOT/etc/modulefiles/Toolchain
