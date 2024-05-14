package: SWIG
version: 4.2.0
build_requires:
  - "autotools:(slc6|slc7)"
  - "GCC-Toolchain:(?!osx)"
  - curl
env:
  SWIG_LIB: "$SWIG_ROOT/share/swig/$SWIG_VERSION"
prefer_system: (?!slc5)
prefer_system_check: |
  verge() {
      [  "$1" = "`echo -e "$1\n$2" | sort -V | head -n1`" ]
  }
  # Check for swig version or later
  which swig && verge "$PKGVERSION" $(swig -version | grep Version | sed -e 's/[^0-9]*//')
---
#!/bin/sh
URL=http://prdownloads.sourceforge.net/swig/swig-${PKGVERSION}.tar.gz
curl -L $URL | tar --strip-components 1 -C "$SOURCEDIR" -xvvz
rsync -av --delete --exclude '**/.git' $SOURCEDIR/ .
./configure --disable-ccache --without-pcre --prefix=$INSTALLROOT
make ${JOBS+-j $JOBS}
make ${JOBS+-j $JOBS} install
