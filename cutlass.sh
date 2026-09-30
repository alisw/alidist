package: cutlass
version: "%(tag_basename)s"
tag: v4.4.2
license: BSD-3-Clause
source: https://github.com/NVIDIA/cutlass
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

# Source tree, not an install: ONNXRuntime receives $CUTLASS_ROOT as
# FETCHCONTENT_SOURCE_DIR_CUTLASS and add_subdirectory()s it. See
# cudnn_frontend.sh, which exists for the same reason.
# Version from onnxruntime's cmake/deps.txt at the tag we build.
rsync -a --chmod=ug=rwX --exclude '**/.git' --delete --delete-excluded \
      "$SOURCEDIR"/ "$INSTALLROOT"/

MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --cmake > "$MODULEDIR/$PKGNAME"
