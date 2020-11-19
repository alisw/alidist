package: utf8proc
version: "v2.5.0"
tag: v2.5.0
source: https://github.com/JuliaStrings/utf8proc
build_requires:
 - "GCC-Toolchain:(?!osx)"
 - alibuild-recipe-tools
 - CMake
prefer_system: "(?!osx)"
prefer_system_check: |
  printf "#include <utf8proc.h>\n" | c++ -c -I$(brew --prefix utf8proc)/include -xc++ - -o /dev/null 2>&1;
  if [ $? -ne 0 ]; then printf "Use brew install utf8proc"; exit 1; fi
---
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT
make ${JOBS+-j $JOBS} install

mkdir -p etc/modulefiles
alibuild-generate-module > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
