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

# Runs a set of (selected) code checks on the O2 code-base. Assumes the
# compile_commands.json file is available under $O2_ROOT
cp "${O2_ROOT}"/compile_commands.json .

# We will try to setup a list of files to be checked by using 2 specific git commits to compare.

# For this we to retrieve the git directory (hack since we have no other way of getting this info):
O2SOURCEPATH=$(grep -m 1 "SOURCES/O2.*/Common/" compile_commands.json | sed 's|.*\s-I\(/.*SOURCES/O2/.*\)/Common/.*|\1|')
# No source path (or empty source path) means fatal error
if [ -d "${O2SOURCEPATH}" ]; then
  echo "This is a valid directory"
else
  echo "This is not a valid directory"
  exit 1
fi
BASECOMMIT=${O2CHECKCODE_BASECOMMIT:=${ALIBOT_PR_BASE}}
HEADCOMMIT=${O2CHECKCODE_HEADCOMMIT:=${ALIBOT_PR_HEAD}}

# We query git if a base commit was given, which we treat as an indication for a delta check.
if [ -n "${BASECOMMIT}" ]; then
  cd ${O2SOURCEPATH}
  O2_CHECKCODE_CHANGEDFILES=$(git diff ${HEADCOMMIT} ${BASECOMMIT} --name-only)
  # convert to ":" separated list
  O2_CHECKCODE_CHANGEDFILES=$(echo ${O2_CHECKCODE_CHANGEDFILES} | tr -t ' ' ':')
  # exit normally if changeset is null
  if [ "${O2_CHECKCODE_CHANGEDFILES}" == "" ]; then
    echo "Nothing changed with respect to base commit ... not checking anything"
    exit 0
  fi
  cd $OLDPWD
fi

# Call a tool to filter out unwanted sources (ROOT dicts, etc) from the compilations database.
# Further, also optionally restrict the checks on a specific set of files, which can be passed here via means of the
# environment variable O2_CHECKCODE_CHANGEDFILES. The environment variable is supposed to hold a colon separated list of files.
ThinCompilationsDatabase.py -exclude-files '(?:.*G\_\_.*\.cxx|.*\.pb.cc)' ${O2_CHECKCODE_CHANGEDFILES:+-use-files ${O2_CHECKCODE_CHANGEDFILES}}
cp thinned_compile_commands.json compile_commands.json

# List of enabled C++ checks (make sure they are all green)
CHECKS="${O2_CHECKER_CHECKS:--*,modernize-*,-modernize-use-default,-modernize-pass-by-value,-modernize-use-auto,-modernize-use-bool-literals,-modernize-use-using,-modernize-loop-convert,-modernize-use-bool-literals,-modernize-make-unique,aliceO2-member-name}"

# Run C++ checks
run_O2CodeChecker.py -clang-tidy-binary $(which O2codecheck) -header-filter=.*SOURCES.* ${O2_CHECKER_FIX:+-fix} -checks=${CHECKS} 2>&1 | tee error-log.txt

# Turn warnings into errors
sed -e 's/ warning:/ error:/g' error-log.txt > error-log.txt.0 && mv error-log.txt.0 error-log.txt

# Get full list of .cxx/.h files
O2_SRC=$(python -c 'import json,sys,os; sys.stdout.write( os.path.commonprefix([ x["file"] for x in json.loads(open("compile_commands.json").read()) if not "G__" in x["file"] and x["file"].endswith(".cxx") ]) )')
[[ -e $O2_SRC/CMakeLists.txt ]]

# Run copyright notice check
COPYRIGHT="$(cat <<'EOF'
// Copyright CERN and copyright holders of ALICE O2. This software is
// distributed under the terms of the GNU General Public License v3 (GPL
// Version 3), copied verbatim in the file "COPYING".
//
// See https://alice-o2.web.cern.ch/ for full licensing information.
//
// In applying this license CERN does not waive the privileges and immunities
// granted to it by virtue of its status as an Intergovernmental Organization
// or submit itself to any jurisdiction.
EOF
)"
COPYRIGHT_LINES=$(echo "$COPYRIGHT" | wc -l)
set +x
while read FILE; do
  [[ "$(head -n$COPYRIGHT_LINES "$FILE")" == "$COPYRIGHT" ]] || { printf "$FILE:1:1: error: missing or malformed copyright notice\n" >> error-log.txt; }
done < <(find "$O2_SRC" -name '*.cxx' -o -name '*.h')

# Tell user what to do in case of copyright notice error
if grep -q "malformed copyright notice" error-log.txt; then
  printf "\nerror: Some files are missing the correct copyright notice on top.\n"
  printf "error: Make sure all your source files begin with the following exact lines:\nerror:\n"
  while read LINE; do printf "error: $LINE\n"; done < <(echo "$COPYRIGHT")
  printf "error:\nerror: List of non-compliant files will follow.\n\n"
fi

# Filter the actual errors from the log. Break with nonzero if errors are found
! ( grep " error:" error-log.txt )
