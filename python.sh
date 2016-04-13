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
  python -c 'import matplotlib; import numpy; import certifi ; import sys; sys.exit(1 if sys.version_info < (2, 7) else 0)'
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

# Install extra packages with pip
pip install "numpy==1.9.2"
pip install "certifi==2015.9.6.2"

# Install matplotlib (very tricky)
MATPLOTLIB_VER="1.4.3"
MATPLOTLIB_URL="http://downloads.sourceforge.net/project/matplotlib/matplotlib/matplotlib-${MATPLOTLIB_VER}/matplotlib-${MATPLOTLIB_VER}.tar.gz"
curl -Lo matplotlib.tgz $MATPLOTLIB_URL
tar xzf matplotlib.tgz
cd matplotlib-$MATPLOTLIB_VER
cat > setup.cfg <<EOF
[directories]
basedirlist  = ${FREETYPE_ROOT:+$PWD/fake_freetype_root,$FREETYPE_ROOT,}${LIBPNG_ROOT:+$LIBPNG_ROOT,}${ZLIB_ROOT:+$ZLIB_ROOT,}/usr/X11R6${FREETYPE_ROOT:+,$(freetype-config --prefix)},${LIBPNG_ROOT:+,$(libpng-config --prefix)}

[gui_support]
gtk = False
gtkagg = False
tkagg = False
wxagg = False
macosx = False
EOF

# matplotlib wants include files in <PackageRoot>/include, but this is not the
# case for FreeType: let's fix it
if [[ $FREETYPE_ROOT ]]; then
  mkdir fake_freetype_root
  ln -nfs $FREETYPE_ROOT/include/freetype2 fake_freetype_root/include
fi

python setup.py build
python setup.py install

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
setenv SSL_CERT_FILE [exec python -c "import certifi; print certifi.where()"]
EoF
