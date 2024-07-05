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
rm "$INSTALLROOT/include/CMakeLists.txt" # for some reason it is there                                                                                                                                   

# Modulefile                                                                                                                                                                                             
mkdir -p "etc/modulefiles"
alibuild-generate-module --lib > "etc/modulefiles/$PKGNAME"
mkdir -p "$INSTALLROOT/etc/modulefiles" && rsync -a --delete etc/modulefiles/ "$INSTALLROOT/etc/modulefiles"

