package: dim
version: "%(tag_basename)s"
tag: v20r30
source: https://github.com/alisw/dim
requires:
  - "GCC-Toolchain:(?!osx)"
  - motif
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
rsync -av $SOURCEDIR/ .

# using makefile_did results in a linker error
# there is no doc that points to `makefile_did_good`
# apart from its miraculous appearance on v20r30
mv makefile_did_good makefile_did

# setup.sh is DOS-encoded
tr -d '\015' < setup.sh > setup2.sh
mv setup2.sh setup.sh

# DIM installation needs `gmake` (`make` is not sufficient)
mkdir buildbin
export PATH="$PWD/buildbin:$PATH"
ln -nfs $(which make) buildbin/gmake

# Build (needs special environment)
( export OS=Linux
  source setup.sh
  gmake realclean
  gmake X64=yes )

# Installation
rsync -av dim $INSTALLROOT/include                              # headers
rsync -av --exclude '*.o' --exclude '*.so' --exclude '*.a'  linux/ $INSTALLROOT/bin/  # executables
rsync -av linux/*.so linux/*.a $INSTALLROOT/lib/                # libraries
rsync -av --exclude "webDi*" WebDID/ $INSTALLROOT/WebDID/       #webdid without executables

# Modulefile
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
