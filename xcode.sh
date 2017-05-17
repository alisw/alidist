package: Xcode
version: "1.0"
system_requirement_missing: |
  Please make sure you install Xcode and the command line tools using xcode-select --install
system_requirement: "(osx.*)"
system_requirement_check: |
  xcode-select -p && echo '#include <AvailabilityMacros.h>' | clang++ -x c++ - -c -o /dev/null
---
