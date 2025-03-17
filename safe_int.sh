package: safe_int
version: "v3.0.28a"
tag: 3.0.28a
source: https://github.com/dcleblanc/SafeInt
prefer_system: .*
prefer_system_check: |
  printf "#include <SafeInt.hpp>" | cc -I$(brew --prefix safeint)/include - -xc++ -c -o/dev/null
---
#!/bin/bash -e
mkdir -p $INSTALLROOT/include
cp -r  $SOURCEDIR/SafeInt.hpp $SOURCEDIR/safe_math.h $SOURCEDIR/safe_math_impl.h $INSTALLROOT/include
