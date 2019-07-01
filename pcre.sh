package: PCRE
version: master
tag: master
source: https://github.com/ktf/pcre
prefer_system: (?!slc5)
prefer_system_check: |
  printf "#include \"pcre.h\"\n" | c++ -I`brew --prefix pcre`/include -xc++ - -c -o /dev/null
---
#!/bin/sh
echo "Building our own pcre. If you want to avoid this, please install pcre development package."

$SOURCEDIR/configure --enable-unicode-properties \
                     --enable-pcregrep-libz \
                     --enable-pcregrep-libbz2 \
                     --prefix=$INSTALLROOT

make ${JOBS+-j $JOBS}
make install
