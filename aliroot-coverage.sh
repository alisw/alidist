package: AliRoot-coverage
version: "%(year)s%(month)s%(day)s"
force_rebuild: true
requires:
  - lcov
  - AliRoot-test
---
#!/bin/sh
# Uses the same setup as AliRoot
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  source $ALIROOT_ROOT/etc/gcov-setup.sh
fi

mkdir -p $WORK_DIR/$ARCHITECTURE/profile-web
# Run coverage analysis directly from aliBuild
if [[ $CMAKE_BUILD_TYPE == COVERAGE ]]; then
  lcov --capture --directory $WORK_DIR/$ARCHITECTURE/profile-data --output-file $WORK_DIR/$ARCHITECTURE/profile-web/coverage.info
  genhtml $WORK_DIR/$ARCHITECTURE/profile-web/coverage.info --output-directory $WORK_DIR/$ARCHITECTURE/profile-web/out
  pushd $WORK_DIR/$ARCHITECTURE/profile-web/out ; zip -r ${WORKSPACE:-..}/coverage-`date +%Y%m%d`-$BUILD_NUMBER.zip . ; popd
fi
