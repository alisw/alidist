package: RivetTask
version: "%(year)s%(month)s%(day)s"
source: https://gitlab.cern.ch/cholm/alice-rivet-task
requires:
  - Rivet
  - AliRoot
build_requires:
  - GCC-Toolchain:(?!osx)
  - alibuild-recipe-tools
---
#!/bin/bash -e

# Echo all commands
set -x

# Picking up ROOT from the system when ours is disabled
[[ -z "$ROOT_ROOT" ]] && ROOT_ROOT="$(root-config --prefix)"

# Print environment to see what is going on - debugging
printenv

# Copy code here
cp "$SOURCEDIR/AliRivetTask.C" .
cp "$SOURCEDIR/Build.C" .

# Use AcLic to build
root -l -b -q Build.C

# Install binary, scripts, and code
mkdir -p "$INSTALLROOT/lib"
mkdir -p "$INSTALLROOT/include"
mkdir -p "$INSTALLROOT/share"
cp "$SOURCEDIR/AliRivetTask.C"  "$INSTALLROOT/include"
cp "$SOURCEDIR/AliRivetTask_C"* "$INSTALLROOT/lib/"
cp "$SOURCEDIR/AddTaskRivet.C"  "$INSTALLROOT/share/"
cp "$SOURCEDIR/RivetConfig.C"   "$INSTALLROOT/share/"

#ModuleFile
mkdir -p etc/modulefiles
alibuild-generate-module > "etc/modulefiles/$PKGNAME"
mkdir -p "$INSTALLROOT/etc/modulefiles"
rsync -a --delete modulefiles/ "$INSTALLROOT/etc/modulefiles"
