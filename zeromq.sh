package: ZeroMQ
version: v4.3.3
source: https://github.com/zeromq/libzmq
requires:
  - "GCC-Toolchain:(?!osx)"
build_requires:
  - autotools
  - alibuild-recipe-tools
prefer_system: (?!slc5.*)
prefer_system_check: |
  printf "#include <zmq.h>\n#if(ZMQ_VERSION < 40105)\n#error \"zmq version >= 4.1.5 needed\"\n#endif\n int main(){}" | c++ -I$(brew --prefix zeromq)/include -xc++ - -o /dev/null 2>&1
---
#!/bin/sh

# Hack to avoid having to do autogen inside $SOURCEDIR
rsync -a --exclude '**/.git' --delete $SOURCEDIR/ $BUILDDIR
cd $BUILDDIR
./autogen.sh
./configure --prefix=$INSTALLROOT          \
            --disable-dependency-tracking

make ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --lib > $MODULEFILE
