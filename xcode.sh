package: Xcode
version: "1.0"
prefer_system: ".*"
prefer_system_check: |
  # In case we are not on Darwin, this should not be included
  case $(uname -o) in
    Darwin) ;;
    *) echo "alibuild_system_replace: unsupported" ;;
  esac
  xcode-select -p && echo '#include <AvailabilityMacros.h>' | clang++ -x c++ - -c -o /dev/null
  XCODE_VERSION="$(xcode-select -v | sed -e 's/[^0-9]//g')"
  echo "alibuild_system_replace: ${XCODE_VERSION}${USE_RECC:+-recc}"
prefer_system_replacement_specs:
  unsupported:
    version: "unsupported"
    recipe: |
      echo "XCode not supported on $(uname -o). Please check your dependencies."
      exit 1
  "^[0-9]+$":
    version: "%(key)s"
    recipe: |
      exit 0
  "^[0-9]+-recc$":
    version: "%(key)s"
    env:
      CXX: "recc-c++"
      CC: "recc-cc"
    recipe: |
      mkdir -p $INSTALLROOT/bin
      ln -s $(which recc-cc) $INSTALLROOT/bin/cc
      ln -s $(which recc-cc) $INSTALLROOT/bin/gcc
      ln -s $(which recc-cc) $INSTALLROOT/bin/clang
      ln -s $(which recc-c++) $INSTALLROOT/bin/g++
      ln -s $(which recc-c++) $INSTALLROOT/bin/c++
      ln -s $(which recc-c++) $INSTALLROOT/bin/clang++
      exit 0
---
echo "Please make sure you install Xcode and the command line tools using xcode-select --install."
exit 1
