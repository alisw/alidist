package: PyTorch
version: "%(tag_basename)s"
tag: "2.2.1"
build_requires:
  - alibuild-recipe-tools
  - curl:(?!osx)
prepend_path:
  CMAKE_PREFIX_PATH: "$PYTORCH_ROOT/share/cmake"
---
#!/bin/bash -e
curl -fSsLo pytorch.zip "https://download.pytorch.org/libtorch/cpu/libtorch-cxx11-abi-shared-with-deps-$PKGVERSION%2Bcpu.zip"
unzip -o pytorch.zip -d "$BUILDDIR"
mv "$BUILDDIR/libtorch"/* "$INSTALLROOT/"

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --lib > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
