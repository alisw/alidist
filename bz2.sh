package: bz2
version: "1.0.8"
tag: 8ca1faa31f396d94ab927b257f3a05236c84e330
source: https://github.com/alisw/bzip2
build_requires:
  - "GCC-Toolchain:(?!osx)"
  - Xcode:osx.*
  - alibuild-recipe-tools
prefer_system: "(?!slc5)"
prefer_system_check: |
  printf "#include <bzlib.h>\n" | c++ -xc++ - -c -o /dev/null
---
# Notice how this will build just the archive library.
rsync -a --delete --exclude '**/.git' --delete-excluded $SOURCEDIR/ ./

make ${JOBS:+-j $JOBS} ${CC:+"CC=$CC"} ${CXX:+"CXX=$CXX"} CFLAGS="-O2 -fPIC -D_FILE_OFFSET_BITS=64" PREFIX=$INSTALLROOT install
rm -rf $INSTALLROOT/bin/bzfgrep $INSTALLROOT/bin/bzegrep $INSTALLROOT/bin/bzcmp $INSTALLROOT/bin/bzless
ln ./bzgrep $INSTALLROOT/bin/bzfgrep
ln ./bzgrep $INSTALLROOT/bin/bzegrep 
ln ./bzdiff $INSTALLROOT/bin/bzcmp
ln ./bzmore $INSTALLROOT/bin/bzless

# Not really needed. Just in case someone decides to build shared libraries
# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module --bin --lib > $MODULEFILE
