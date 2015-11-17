package: SWIG
version: 3.0.7
source: https://github.com/swig/swig
tag: rel-3.0.7
build_requires:
  - autotools
env:
  SWIG_INC: "$SWIG_ROOT/share/swig/$SWIG_VERSION/"
---
#!/bin/sh
rsync -av --delete --exclude '**/.git' $SOURCEDIR/ .
#aclocal
#autoheader
#automake --force-missing  --copy --add-missing
#autoconf
./autogen.sh
./configure --disable-ccache --without-pcre --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS}
make ${JOBS+-j $JOBS} install
