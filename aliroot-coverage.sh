package: AliRoot-coverage
version: "%(year)s%(month)s%(day)s%(defaults_upper)s"
force_rebuild: 1
requires:
  - AliRoot-test
---
#!/bin/sh
# Uses the same setup as AliRoot
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  source $ALIROOT_ROOT/etc/gcov-setup.sh
fi

# Run coverage analysis directly from aliBuild
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  lcov --capture --directory $WORKDIR/sw/$ARCHITECTURE/profile-data --output-file coverage.info
  genhtml coverage.info --output-directory out
fi
