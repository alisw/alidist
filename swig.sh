package: SWIG
version: 3.0.12
tag: rel-3.0.12
source: https://github.com/swig/swig
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
  - yacc-like
env:
  SWIG_LIB: "$SWIG_ROOT/share/swig/$SWIG_VERSION"
prefer_system: (?!slc5)
prefer_system_check: |
  verge() {
      [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
  }
  # Check for swig 3.0.12 or later
  which swig && verge 3.0.12 $(swig -version | grep Version | sed -e 's/[^0-9]*//')
---
#!/bin/sh
rsync -av --delete --exclude '**/.git' $SOURCEDIR/ .
./autogen.sh
./configure --disable-ccache --without-pcre --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS}
make ${JOBS+-j $JOBS} install
