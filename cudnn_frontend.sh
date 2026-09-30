package: cudnn_frontend
version: "%(tag_basename)s"
tag: v1.24.0
license: MIT
source: https://github.com/NVIDIA/cudnn-frontend
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e

# ONNXRuntime's CUDA provider pulls this in with FetchContent, which aliBuild
# forbids from downloading (-DFETCHCONTENT_FULLY_DISCONNECTED=ON). It is handed
# $CUDNN_FRONTEND_ROOT as FETCHCONTENT_SOURCE_DIR_CUDNN_FRONTEND and calls
# add_subdirectory() on it, so install the source tree rather than headers.
# Version from onnxruntime's cmake/deps.txt at the tag we build.
rsync -a --chmod=ug=rwX --exclude '**/.git' --delete --delete-excluded \
      "$SOURCEDIR"/ "$INSTALLROOT"/

MODULEDIR="$INSTALLROOT/etc/modulefiles"
mkdir -p "$MODULEDIR"
alibuild-generate-module --cmake > "$MODULEDIR/$PKGNAME"
