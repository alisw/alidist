package: UUID
version: v1.6.2
source: https://github.com/alisw/UUID
tag: v1.6.2
build_requires:
 - "GCC-Toolchain:(?!osx)"
---
#!/bin/sh
rsync -av --delete --exclude "**/.git" $SOURCEDIR/ .
./configure --prefix=$INSTALLROOT        \
            --includedir=$SOURCEDIR/ossp \
            --without-perl               \
            --without-php                \
            --without-pgsql

make ${JOBS:+-j$JOBS}
make ${JOBS:+-j$JOBS} install
