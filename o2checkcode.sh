# recipe that actually performce the check
package: o2checkcode
requires:
  - O2
  - o2codechecker
build_requires:
  - CMake
force_rebuild: 1
version: "1.0"
---
#!/bin/bash -e

# run the code checker with the alice specific rules
# and no other enabled rules
# it assumes that there is a compile_commands.json in ${O2_ROOT}
cp ${O2_ROOT}/compile_commands.json .

# do some pre-processing on compile_commands.json
# this could be:
# - filtering out ROOT dictionary results
# - filtering files relevant for pull request etc.

# These are checks which are currently all green, so we should
# Now enable them.
CHECKS="${O2_CHECKER_CHECKS:--*,modernize-*,-modernize-use-auto,-modernize-use-bool-literals,-modernize-use-using,-modernize-loop-convert,-modernize-use-bool-literals,aliceO2-member-name}"
# run actual checks
run_O2CodeChecker.py -clang-tidy-binary `which O2codecheck` ${O2_CHECKER_FIX:+-fix} -checks=$CHECKS 2>&1 | tee error-log.txt

perl -p -i -e 's/ warning:/ error:/g' error-log.txt

if grep -v "/G__" error-log.txt | grep " error:" ; then
  exit 1
fi
