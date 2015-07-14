package: lcov
version: v1.11
source: https://github.com/linux-test-project/lcov.git
tag: v1.11
---
#!/bin/sh
rsync -av $SOURCEDIR/ $BUILDDIR/
make ${JOBS+-j $JOBS}
make PREFIX=$INSTALLROOT BIN_DIR=$INSTALLROOT/bin install
