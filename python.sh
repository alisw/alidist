package: Python
version: "%(tag_basename)s"
tag: alice/v2.7.10
source: https://github.com/alisw/cpython.git
requires:
 - AliEn-Runtime:(?!.*ppc64)
 - FreeType
 - libpng
env:
  SSL_CERT_FILE: "$(export PATH=$PYTHON_ROOT/bin:$PATH; export LD_LIBRARY_PATH=$PYTHON_ROOT/lib:$LD_LIBRARY_PATH; python -c \"import certifi; print certifi.where()\")"
prefer_system: (?!slc5)
prefer_system_check:
  python -c 'import sys; sys.exit(1 if sys.version_info < (2, 7) else 0)' && which pip
---
#!/bin/bash -ex

case $ARCHITECTURE in 
  slc5*) ;;
  *)
    echo "Building our own python. If you want to avoid this, please install python >= 2.7"
    echo "and make sure you have matplotlib and certifi module installed."
  ;;
esac

rsync -av --exclude '**/.git' $SOURCEDIR/ $BUILDDIR/

# The only way to pass externals to Python
LDFLAGS=
CPPFLAGS=
for ext in $ALIEN_RUNTIME_ROOT $ZLIB_ROOT $FREETYPE_ROOT $LIBPNG_ROOT; do
  LDFLAGS="$(find $ext -type d -name lib -exec echo -L\{\} \;) $LDFLAGS"
  CPPFLAGS="$(find $ext -type d -name include -exec echo -I\{\} \;) $CPPFLAGS"
done
export LDFLAGS=$(echo $LDFLAGS)
export CPPFLAGS=$(echo $CPPFLAGS)

./configure --prefix=$INSTALLROOT \
            --enable-shared \
            --with-system-expat \
            --with-system-ffi \
            --enable-unicode=ucs4
make ${JOBS:+-j$JOBS}
make install

# Install pip
cd $BUILDDIR
export PATH=$INSTALLROOT/bin:$PATH
export LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$INSTALLROOT/lib:$DYLD_LIBRARY_PATH
curl -kSsL -o get-pip.py https://bootstrap.pypa.io/get-pip.py
python get-pip.py

# Remove useless stuff
rm -rvf $INSTALLROOT/share \
       $INSTALLROOT/lib/python*/test
find $INSTALLROOT/lib/python* \
     -mindepth 2 -maxdepth 2 -type d -and \( -name test -or -name tests \) \
     -exec rm -rvf '{}' \;

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
module load BASE/1.0 ${ALIEN_RUNTIME_VERSION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION} ${ZLIB_VERSION:+zlib/$ZLIB_VERSION-$ZLIB_REVISION}
# Our environment
setenv PYTHON_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(PYTHON_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(PYTHON_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_ROOT)/lib")
EoF
