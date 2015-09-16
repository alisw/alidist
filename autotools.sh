package: autotools
version: v1.1.0
source: https://github.com/star-externals/autotools
tag: star/v1.1.0
---
#!/bin/sh
export PATH=$INSTALLROOT/bin:$PATH
rsync -a $SOURCEDIR/ $BUILDDIR/
pushd m4
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS} && make install
popd
pushd autoconf
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS} && make install
popd
pushd automake
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT
  make ${JOBS+-j $JOBS} && make install
popd
pushd libtool
  # Update for AArch64 support
  rm -f ./libltdl/config/config.{sub,guess}
  curl -L -k -s -o ./libltdl/config/config.sub 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.sub;hb=HEAD'
  curl -L -k -s -o ./libltdl/config/config.guess 'http://git.savannah.gnu.org/gitweb/?p=config.git;a=blob_plain;f=config.guess;hb=HEAD'
  chmod +x ./libltdl/config/config.{sub,guess}
  ./configure --disable-dependency-tracking --prefix $INSTALLROOT --enable-ltdl-install
  make ${JOBS+-j $JOBS} && make install
popd
pushd gettext
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
pushd pkg-config
    ./configure --disable-debug \
                --prefix=$INSTALLROOT \
                --disable-host-tool \
                --with-internal-glib
  make ${JOBS+-j $JOBS} && make install
popd

# Fix perl location, required on /usr/bin/perl
grep -l -R -e '^#!.*perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;^#!.*perl;#!/usr/bin/perl;'
find $INSTALLROOT -name '*deleteme' -delete
grep -l -R -e 'exec [^ ]*/perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;exec [^ ]*/perl;exec /usr/bin/perl;g'
find $INSTALLROOT -name '*deleteme' -delete

# Fix perl location, required on /usr/bin/perl
grep -l -R -e '^#!.*perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;^#!.*perl;#!/usr/bin/perl;'
find $INSTALLROOT -name '*deleteme' -delete
grep -l -R -e 'exec [^ ]*/perl' $INSTALLROOT | xargs -n1 sed -ideleteme -e 's;exec [^ ]*/perl;exec /usr/bin/perl;g'
find $INSTALLROOT -name '*deleteme' -delete

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
cat > "$MODULEFILE" <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0
# Our environment
setenv AUTOTOOLS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(AUTOTOOLS_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(AUTOTOOLS_ROOT)/lib
EoF
