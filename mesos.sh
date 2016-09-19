package: mesos
version: v0.28.2
source: https://git-wip-us.apache.org/repos/asf/mesos.git
tag: 0.28.2
requires:
- protobuf
build_requires:
- autotools
- glog
- Python
prepend_path:
  PATH: "$MESOS_ROOT/sbin"
  PYTHONPATH: "$MESOS_ROOT/lib/python$(python -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')/site-packages"
---
#/bin/bash -e
rsync -av --delete --exclude="**/.git" $SOURCEDIR/ .
ALIBUILD_PYTHONPATH=$(IFS=:; for P in $PYTHONPATH; do [[ "$P" != "$WORK_DIR"* ]] || printf "$P:"; done)
cat src/Makefile.am | sed -e 's@^\(pippythonpath =.*\)@\1:'"$ALIBUILD_PYTHONPATH"'@' > src/Makefile.am.0
mv src/Makefile.am.0 src/Makefile.am
./bootstrap
mkdir build
cd build
unset PYTHON_VERSION  # clashes with what configure uses to determine Python version
../configure --prefix="$INSTALLROOT"             \
             --enable-python                     \
             --disable-python-dependency-install \
             --disable-java                      \
             --with-glog=$GLOG_ROOT              \
             --with-protobuf=$PROTOBUF_ROOT
make -j ${JOBS:+-j $JOBS} || make -j 4  # fallback to fewer jobs in case of GCC OOM errors
make install

# Test whether Python modules were installed properly (installation might fail silently!)
export MESOS_PYTHONPATH=lib/python$(python -c 'import distutils.sysconfig; print(distutils.sysconfig.get_python_version())')/site-packages
export PYTHONPATH=$INSTALLROOT/$MESOS_PYTHONPATH:$PYTHONPATH
[[ "$(python -c 'import mesos; print(mesos.__file__)')" == "$INSTALLROOT/$MESOS_PYTHONPATH"* ]]

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
module load BASE/1.0 protobuf/$PROTOBUF_VERSION-$PROTOBUF_REVISION glog/$GLOG_VERSION-$GLOG_REVISION
# Our environment
setenv MESOS_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
prepend-path PYTHONPATH \$::env(MESOS_ROOT)/$MESOS_PYTHONPATH
prepend-path LD_LIBRARY_PATH \$::env(MESOS_ROOT)/lib
$([[ ${ARCHITECTURE:0:3} == osx ]] && echo "prepend-path DYLD_LIBRARY_PATH \$::env(MESOS_ROOT)/lib")
prepend-path PATH \$::env(MESOS_ROOT)/bin
prepend-path PATH \$::env(MESOS_ROOT)/sbin
EoF
