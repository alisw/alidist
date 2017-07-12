package: autotools
version: "%(tag_basename)s"
source: https://github.com/alisw/autotools
tag: v1.4.0
prefer_system: "(?!slc5|slc6)"
prefer_system_check: |
  export PATH=$PATH:$(brew --prefix gettext || true)/bin;
  which autoconf && which m4 && which automake && which makeinfo && which aclocal && which pkg-config && which autopoint && which libtool;
  if [ $? -ne 0 ]; then printf "One or more autotools packages are missing on your system.\n * On a RHEL-compatible system you probably need: autoconf automake texinfo gettext gettext-devel libtool\n * On an Ubuntu-like system you probably need: autoconf automake autopoint texinfo gettext libtool libtool-bin pkg-config"; exit 1; fi
prepend_path:
  PKG_CONFIG_PATH: $(pkg-config --debug 2>&1 | grep 'Scanning directory' | sed -e "s/.*'\(.*\)'/\1/" | xargs echo | sed -e 's/ /:/g')
build_requires:
 - termcap
---
#!/bin/bash -e

unset CXXFLAGS
unset CFLAGS
export EMACS=no

echo "Building ALICE autotools. To avoid this install autoconf, automake, autopoint, texinfo, pkg-config."

# Restore original timestamps to avoid reconf (Git does not preserve them)
pushd $SOURCEDIR
  ./missing-timestamps.sh --apply
popd

rsync -a --delete --exclude '**/.git' $SOURCEDIR/ .

# Use our auto* tools while we build them
export PATH=$INSTALLROOT/bin:$PATH
export LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$INSTALLROOT/lib:$DYLD_LIBRARY_PATH

# m4 -- requires: nothing special
pushd m4*
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# libtool -- requires: m4
pushd libtool*
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT --enable-ltdl-install
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# autoconf -- requires: m4
pushd autoconf*
  ./configure --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# gettext -- requires: nothing special
pushd gettext*
  ./configure --prefix $INSTALLROOT \
              --without-xz \
              --without-bzip2 \
              --disable-curses \
              --disable-openmp \
              --enable-relocatable \
              --disable-rpath \
              --disable-nls \
              --disable-native-java \
              --disable-acl \
              --disable-java \
              --disable-dependency-tracking \
              --disable-silent-rules
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# automake -- requires: m4, autoconf, gettext
pushd automake*
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# pkgconfig -- requires: nothing special
pushd pkg-config*
  OLD_LDFLAGS="$LDFLAGS"
  [[ ${ARCHITECTURE:0:3} == osx ]] && export LDFLAGS="$LDFLAGS -framework CoreFoundation -framework Carbon"
  ./configure --disable-debug \
              --prefix=$INSTALLROOT \
              --disable-host-tool \
              --with-internal-glib
  export LDFLAGS="$OLD_LDFLAGS"
  make ${JOBS+-j $JOBS}
  make install
  hash -r
popd

# We need to detect OSX becase xargs behaves differently there
XARGS_DO_NOT_FAIL='-r'
[[ ${ARCHITECTURE:0:3} == osx ]] && XARGS_DO_NOT_FAIL=

# Fix perl location, required on /usr/bin/perl
grep -l -R -e '^#!.*perl' $INSTALLROOT | \
  xargs ${XARGS_DO_NOT_FAIL} -n1 sed -ideleteme -e 's;^#!.*perl;#!/usr/bin/perl;'
find $INSTALLROOT -name '*deleteme' -delete
grep -l -R -e 'exec [^ ]*/perl' $INSTALLROOT | \
  xargs ${XARGS_DO_NOT_FAIL} -n1 sed -ideleteme -e 's;exec [^ ]*/perl;exec /usr/bin/perl;g'
find $INSTALLROOT -name '*deleteme' -delete
