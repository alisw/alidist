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
  echo "alibuild_system_replace: ${XCODE_VERSION}"
prefer_system_replacement_specs:
  unsupported:
    version: "unsupported"
    recipe: |
      echo "XCode not supported on $(uname -o). Please check your dependencies."
      exit 1
  "[0-9]+":
    version: "%(key)s"
    recipe: |
      exit 0
---
echo "Please make sure you install Xcode and the command line tools using xcode-select --install."
exit 1
