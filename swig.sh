package: SWIG
version: 3.0.7
source: https://github.com/swig/swig
tag: rel-3.0.7
build_requires:
  - autotools
  - "GCC-Toolchain:(?!osx)"
env:
  SWIG_LIB: "$SWIG_ROOT/share/swig/$SWIG_VERSION"
prefer_system: (?!slc5)
prefer_system_check: which swig
---
#!/bin/sh
rsync -av --delete --exclude '**/.git' $SOURCEDIR/ .
./autogen.sh
./configure --disable-ccache --without-pcre --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS}
make ${JOBS+-j $JOBS} install
