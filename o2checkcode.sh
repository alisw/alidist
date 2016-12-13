# recipe that actually performce the check
package: o2checkcode
requires:
  - O2
  - o2codechecker
build_requires:
  - CMake
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


# run actual checks
run_O2CodeChecker.py -clang-tidy-binary `which O2codecheck` -checks=-*,alice*

# exit with the return code from the checker
exit $?
