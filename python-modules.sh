package: Python-modules
version: "1.0"
requires:
  - "Python:(?!osx)"
  - "Python-system:(osx)"
  - FreeType
  - libpng
build_requires:
  - curl
prepend_path:
  PYTHONPATH: $PYTHON_MODULES_ROOT/lib/python/site-packages
---
#!/bin/bash -ex

# Major.minor version of Python
export PYVER=$(python3 -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')

# Ignore what is already in PYTHONPATH. We will set PYTHONPATH or PYTHONUSERBASE per command
unset PYTHONPATH

# *** IMPORTANT NOTE FOR CONTRIBUTORS ***
# In order to ensure reproducibility (i.e. if we rebuild this same package over time we want to get
# the exact same result) we absolutely need to specify the exact versions of the desired packages.
# In order to get the exact versions, you can use `pip freeze` on your local installation.
PIP_REQUIREMENTS=(
  # pack==version           import_module
  "requests==2.21.0         requests"
  "ipykernel==5.1.0         ipykernel"
  "ipython==7.4.0           IPython"
  "ipywidgets==7.4.2        ipywidgets"
  "Keras==2.2.4             keras"
  "metakernel==0.20.14      metakernel"
  "mock==2.0.0              mock"
  "notebook==5.7.8          notebook.notebookapp"
  "numpy==1.16.2            numpy"
  "pandas==0.24.2           pandas"
  "PyYAML==5.1              yaml"
  "scikit-learn==0.20.3     sklearn"
  "scipy==1.2.1             scipy"
  "seaborn==0.9.0           seaborn"
  "sklearn-evaluation==0.4  sklearn_evaluation"
  "tensorflow==1.13.1       tensorflow"
  "uproot==3.4.18           uproot"
  "xgboost==0.82            xgboost")

# Install pip packages under a user folder, but unset it right after installation
for P in "${PIP_REQUIREMENTS[@]}"; do
  echo $P | cut -d' ' -f1
done > requirements.txt
env PYTHONUSERBASE="$INSTALLROOT" pip3 install --user -IU -r requirements.txt

# Find the proper Python lib library and export it
pushd "$INSTALLROOT"
  if [[ -d lib64 ]]; then
    ln -nfs lib64 lib  # creates lib pointing to lib64
  fi
  pushd lib
    ln -nfs python$PYVER python
  popd
popd

# Check if the modules can be loaded
IMPORT=
for P in "${PIP_REQUIREMENTS[@]}"; do
  IMPORT="$IMPORT,${P##* }"
done
IMPORT=${IMPORT:1}
env PYTHONPATH="$INSTALLROOT/lib/python/site-packages" python3 -c "import $IMPORT"

# Install matplotlib (quite tricky)
MATPLOTLIB_TAG="3.0.3"
if [[ $ARCHITECTURE != slc* ]]; then
  # Simply get it via pip in most cases
  env PYTHONUSERBASE=$INSTALLROOT pip3 install "matplotlib==$MATPLOTLIB_TAG"
else

  # We are on a RHEL-compatible OS. We compile it ourselves, and link it to our dependencies

  # Check if we can enable the Tk interface
  python3 -c 'import _tkinter' && MATPLOTLIB_TKAGG=True || MATPLOTLIB_TKAGG=False
  MATPLOTLIB_URL="https://github.com/matplotlib/matplotlib/archive/v${MATPLOTLIB_TAG}.tar.gz"  # note the "v"
  curl -SsL "$MATPLOTLIB_URL" | tar xzf -
  cd matplotlib-*
  cat > setup.cfg <<EOF
[directories]
basedirlist  = ${FREETYPE_ROOT:+$PWD/fake_freetype_root,$FREETYPE_ROOT,}${LIBPNG_ROOT:+$LIBPNG_ROOT,}${ZLIB_ROOT:+$ZLIB_ROOT,}/usr/X11R6,$(freetype-config --prefix),$(libpng-config --prefix)
[gui_support]
gtk = False
gtkagg = False
tkagg = $MATPLOTLIB_TKAGG
wxagg = False
macosx = False
EOF

  # matplotlib wants include files in <PackageRoot>/include, but this is not the case for FreeType
  if [[ $FREETYPE_ROOT ]]; then
    mkdir fake_freetype_root
    ln -nfs $FREETYPE_ROOT/include/freetype2 fake_freetype_root/include
  fi

  export PYTHONPATH="$INSTALLROOT/lib/python/site-packages"
    python3 setup.py build
    python3 setup.py install --prefix "$INSTALLROOT"
  unset PYTHONPATH
fi

# Test if matplotlib can be loaded
env PYTHONPATH="$INSTALLROOT/lib/python/site-packages" python3 -c 'import matplotlib'

# Patch long shebangs (by default max is 128 chars on Linux)
pushd "$INSTALLROOT/bin"
  sed -i.deleteme -e "1 s|^#!${INSTALLROOT}/bin/\(.*\)$|#!/usr/bin/env \1|" * || true
  rm -f *.deleteme
popd

# Remove useless stuff
rm -rvf "$INSTALLROOT"/share "$INSTALLROOT"/lib/python*/test
find "$INSTALLROOT"/lib/python* \
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
prepend-path LD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH $::env(PYTHON_MODULES_ROOT)/lib")
prepend-path PYTHONPATH $::env(PYTHON_MODULES_ROOT)/lib/python/site-packages
EoF
