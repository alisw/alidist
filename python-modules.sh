package: Python-modules
version: "1.0"
requires:
  - Python
  - FreeType
  - libpng
build_requires:
  - curl
env:
  SSL_CERT_FILE: "$(env PYTHONPATH=$PYTHON_MODULES_ROOT/lib/python$(python -c \"import distutils.sysconfig; print(distutils.sysconfig.get_python_version())\")/site-packages:$PYTHONPATH python -c \"import certifi; print certifi.where()\")"
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/lib/python2.7/site-packages:$PYTHONPATH
prefer_system: (?!slc5)
prefer_system_check:
  python -c 'import matplotlib; import numpy; import certifi; import IPython; import ipykernel; import yaml'
---
#!/bin/bash -ex

# Force pip installation of packages found in current PYTHONPATH
unset PYTHONPATH

# The X.Y in pythonX.Y
export PYVER=$(python -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')

# Install as much as possible with pip
export PYTHONUSERBASE=$INSTALLROOT
for X in "mock==1.0.0"         \
         "numpy==1.9.2"        \
         "certifi==2015.9.6.2" \
         "ipython==5.1.0"      \
         "ipykernel==4.5.0"    \
         "pyyaml";
do
  pip install --user $X
done
unset PYTHONUSERBASE

# Install matplotlib (quite tricky)
MATPLOTLIB_VER="1.4.3"
MATPLOTLIB_URL="http://downloads.sourceforge.net/project/matplotlib/matplotlib/matplotlib-${MATPLOTLIB_VER}/matplotlib-${MATPLOTLIB_VER}.tar.gz"
curl -Lo matplotlib.tgz $MATPLOTLIB_URL
tar xzf matplotlib.tgz
cd matplotlib-$MATPLOTLIB_VER
cat > setup.cfg <<EOF
[directories]
basedirlist  = ${FREETYPE_ROOT:+$PWD/fake_freetype_root,$FREETYPE_ROOT,}${LIBPNG_ROOT:+$LIBPNG_ROOT,}${ZLIB_ROOT:+$ZLIB_ROOT,}/usr/X11R6,$(freetype-config --prefix),$(libpng-config --prefix)
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
perl -p -i -e "s|'darwin': \['/usr/local/'|'darwin': ['$INSTALLROOT'|g" setupext.py

mkdir -p $INSTALLROOT/lib/python$PYVER/site-packages \
         $INSTALLROOT/lib64/python$PYVER/site-packages
python setup.py build
PYTHONPATH=$INSTALLROOT/lib64/python$PYVER/site-packages:$INSTALLROOT/lib/python$PYVER/site-packages:$PYTHONPATH \
  python setup.py install --prefix $INSTALLROOT

# Remove unneeded stuff
rm -rvf $INSTALLROOT/share            \
        $INSTALLROOT/lib/python*/test
find $INSTALLROOT/lib/python*                                              \
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
module load BASE/1.0 ${PYTHON_VERSION:+Python/$PYTHON_VERSION-$PYTHON_REVISION} ${ALIEN_RUNTIME_VERSION:+AliEn-Runtime/$ALIEN_RUNTIME_VERSION-$ALIEN_RUNTIME_REVISION}
# Our environment
setenv PYTHON_MODULES_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PATH $::env(PYTHON_MODULES_ROOT)/bin
prepend-path LD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib64
prepend-path LD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib64" && \
                                      echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib")
prepend-path PYTHONPATH $::env(PYTHON_MODULES_ROOT)/lib/python$PYVER/site-packages
setenv SSL_CERT_FILE  [exec python -c "import certifi; print certifi.where()"]
EoF
