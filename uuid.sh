package: UUID
version: v1.6.2
source: https://github.com/alisw/UUID
tag: v1.6.2
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
