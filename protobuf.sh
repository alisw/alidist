package: protobuf
version: v2.6.1
source: https://github.com/google/protobuf
build_requires:
 - Python
 - autotools
 - "GCC-Toolchain:(?!osx)"
env:
  PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION: "cpp"
  PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION: "2"
prepend_path:
  PYTHONPATH: "$PROTOBUF_ROOT/lib/python$(python -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')/site-packages"
---

rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
autoreconf -ivf
./configure --prefix="$INSTALLROOT"
make ${JOBS:+-j $JOBS}
make install

export PATH=$INSTALLROOT/bin:$PATH
export LD_LIBRARY_PATH=$INSTALLROOT/lib:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$INSTALLROOT/lib:$DYLD_LIBRARY_PATH
protoc --version

pushd python
  export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=cpp
  export PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION=2
  PROTOBUF_PYTHONPATH=lib/python$(python -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')/site-packages
  mkdir -p $INSTALLROOT/$PROTOBUF_PYTHONPATH
  export PYTHONPATH=$INSTALLROOT/$PROTOBUF_PYTHONPATH:$PYTHONPATH
  python setup.py build
  python setup.py install --cpp_implementation --prefix=$INSTALLROOT
popd
[[ $(python -c 'import google.protobuf; print(google.protobuf.__file__)') == "$INSTALLROOT/$PROTOBUF_PYTHONPATH"* ]]

#ModuleFile
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
setenv PROTOBUF_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION cpp
setenv PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION_VERSION 2
prepend-path LD_LIBRARY_PATH \$::env(PROTOBUF_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(PROTOBUF_ROOT)/lib")
prepend-path PATH \$::env(PROTOBUF_ROOT)/bin
prepend-path PYTHONPATH \$::env(PROTOBUF_ROOT)/$PROTOBUF_PYTHONPATH
EoF
