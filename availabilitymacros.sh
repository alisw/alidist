package: availabilitymacros
version: 1.0
system_requirement_missing: |
  Please make sure you install xcode command line tools using xcode-select --install
system_requirement: "osx.*"
system_requirement_check: |
  echo '#include <AvailabilityMacros.h>' | c++ -x c++ - -c -o /dev/null
---