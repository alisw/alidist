package: moderncppkafka
version: "%(tag_basename)s"
tag: v2023.03.07
requires:
  - librdkafka
source: https://github.com/morganstanley/modern-cpp-kafka.git
---
#!/bin/bash -e

# this is header only library, so we can just copy it
mkdir -p "$INSTALLROOT"
cp -r "$SOURCEDIR/include" "$INSTALLROOT/include"

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"

mkdir -p "etc/modulefiles"
alibuild-generate-module --lib > "etc/modulefiles/$PKGNAME"

cat << EOF >> etc/modulefiles/$PKGNAME
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EOF
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
