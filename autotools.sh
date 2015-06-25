package: autotools
version: v1.0.0
source: https://github.com/star-externals/autotools
branch: star/v1.0.0
tag: HEAD
---
#!/bin/sh
SOURCE0=https://github.com/star-externals/autotools
BUILDDIR=$BUILDROOT/$PKGNAME
GIT_REFERENCE=$SOURCEDIR/$PKGNAME


git clone ${GIT_REFERENCE+--reference $GIT_REFERENCE} $SOURCE0 $BUILDDIR

cd $BUILDDIR
git checkout star/$PKGVERSION

export PATH=$INSTALLROOT/bin:$PATH
pushd $BUILDDIR/m4
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS} && make install
popd
pushd $BUILDDIR/autoconf
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS} && make install
popd
pushd $BUILDDIR/automake
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS} && make install
popd
pushd $BUILDDIR/libtool
  # Update for AArch64 support
  rm -f ./libltdl/config/config.{sub,guess}
  curl -L -k -s -o ./libltdl/config/config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
  curl -L -k -s -o ./libltdl/config/config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
  chmod +x ./libltdl/config/config.{sub,guess}
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT --enable-ltdl-install
  make ${JOBS+-j $JOBS} && make install
popd
pushd $BUILDDIR/gettext
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
  make ${JOBS+-j $JOBS} && make install
popd

# Fix perl location, required on /usr/bin/perl
grep -l -R '/bin/perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;^#!.*perl;#!/usr/bin/perl;'
find $INSTALLROOT -name '*deleteme' -delete
grep -l -R '/bin/perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;exec [^ ]*/perl;exec /usr/bin/perl;g'
find $INSTALLROOT -name '*deleteme' -delete

# Fix perl location, required on /usr/bin/perl
grep -l -R '/bin/perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;^#!.*perl;#!/usr/bin/perl;'
find $INSTALLROOT -name '*deleteme' -delete
grep -l -R '/bin/perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;exec [^ ]*/perl;exec /usr/bin/perl;g'
find $INSTALLROOT -name '*deleteme' -delete
