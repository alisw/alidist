package: utf8proc
version: "v2.6.1"
tag: v2.6.1
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
cmake $SOURCEDIR -DCMAKE_INSTALL_PREFIX=$INSTALLROOT -DBUILD_SHARED_LIBS=ON
make ${JOBS+-j $JOBS} install

mkdir -p etc/modulefiles
alibuild-generate-module --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
