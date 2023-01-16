package: o2checkcode
version: "1.0"
requires:
  - O2
  - o2codechecker
build_requires:
  - CMake
force_rebuild: true
---
#!/bin/bash -e

# Runs a set of (selected) code checks on the O2 code-base. Assumes the
# compile_commands.json file is available under $O2_ROOT
cp "${O2_ROOT}"/compile_commands.json .

# We will try to setup a list of files to be checked by using 2 specific Git commits to compare

# Heuristically guess source directory
O2_SRC=$(python3 -c 'import json, os; print(os.path.commonprefix([x["file"] for x in json.loads(open("compile_commands.json").read()) if "sw/BUILD" not in x["file"] and "G__" not in x["file"] and x["file"].endswith(".cxx")]))')
[[ -e "$O2_SRC"/CMakeLists.txt && -d "$O2_SRC"/.git ]]

# We have something to compare our working directory to (ALIBUILD_BASE_HASH). We check only the
# changed files (including the untracked ones) if the list of relevant files that changed is up to
# 50 entries long
if [[ $ALIBUILD_BASE_HASH ]]; then
  pushd "$O2_SRC"
    ( git diff --name-only $ALIBUILD_BASE_HASH${ALIBUILD_HEAD_HASH:+...$ALIBUILD_HEAD_HASH} || true ; git ls-files --others --exclude-standard ) | ( grep -E '\.cxx$|\.h$' || true ) | sort -u > $BUILDDIR/changed
    if [[ $(cat $BUILDDIR/changed | wc -l) -le 50 ]]; then
      O2_CHECKCODE_CHANGEDFILES=$(while read FILE; do [[ -e "$O2_SRC/$FILE" ]] && echo "$FILE" || true; done < <(cat $BUILDDIR/changed) | \
                                  xargs echo | sed -e 's/ /:/g')
      if [[ ! $O2_CHECKCODE_CHANGEDFILES ]]; then
        echo "Nothing changed with respect to base commit: not checking anything"
        exit 0
      fi
    fi
  popd
fi

# Call a tool to filter out unwanted sources (ROOT dicts, etc) from the compilations database.
# Further, also optionally restrict the checks on a specific set of files, which can be passed here via means of the
# environment variable O2_CHECKCODE_CHANGEDFILES. The environment variable is supposed to hold a colon separated list of files.
ThinCompilationsDatabase.py -exclude-files '(?:.*G\_\_.*\.cxx|.*\.pb.cc)' ${O2_CHECKCODE_CHANGEDFILES:+-use-files ${O2_CHECKCODE_CHANGEDFILES}}
cp thinned_compile_commands.json compile_commands.json

# List of explicitely enabled C++ checks (make sure they are all green)
CHECKS="${O2_CHECKER_CHECKS:--*\
,aliceO2-member-name\
,aliceO2-namespace-naming\
,modernize-avoid-bind\
,modernize-deprecated-headers\
,modernize-make-shared\
,modernize-raw-string-literal\
,modernize-redundant-void-arg\
,modernize-replace-auto-ptr\
,modernize-replace-random-shuffle\
,modernize-shrink-to-fit\
,modernize-unary-static-assert\
,modernize-use-equals-default\
,modernize-use-noexcept\
,modernize-use-nullptr\
,modernize-use-override\
,modernize-use-transparent-functors\
,modernize-use-uncaught-exceptions\
,readability-braces-around-statements\
}"

# Run C++ checks
run_O2CodeChecker.py ${JOBS+-j $JOBS} \
	-clang-tidy-binary $(which O2codecheck) \
	-clang-apply-replacements-binary "$CLANG_ROOT/bin-safe/clang-apply-replacements" \
	-header-filter=.*SOURCES.* ${O2_CHECKER_FIX:+-fix} -checks=${CHECKS} 2>&1 | tee error-log.txt

# Turn warnings into errors
sed -e 's/ warning:/ error:/g' error-log.txt > error-log.txt.0 && mv error-log.txt.0 error-log.txt

# Run copyright notice check
COPYRIGHT="$(cat <<'EOF'
// Copyright 2019-2020 CERN and copyright holders of ALICE O2.
// See https://alice-o2.web.cern.ch/copyright for details of the copyright holders.
// All rights not expressly granted are reserved.
//
// This software is distributed under the terms of the GNU General Public
// License v3 (GPL Version 3), copied verbatim in the file "COPYING".
//
// In applying this license CERN does not waive the privileges and immunities
// granted to it by virtue of its status as an Intergovernmental Organization
// or submit itself to any jurisdiction.
EOF
)"
COPYRIGHT_LINES=$(echo "$COPYRIGHT" | wc -l)
COPYRIGHT_EXCLUDE_REGEXP="/3rdparty/|Utilities/Tools/cpulimit/"  # exclude files from the copyright check
set +x
while read FILE; do
  [[ ${FILE:0:2} != "./" ]] || FILE=${FILE:2}
  [[ ! $FILE =~ $COPYRIGHT_EXCLUDE_REGEXP ]] || continue
  FILE="$O2_SRC/$FILE"
  [[ "$(head -n$COPYRIGHT_LINES "$FILE")" == "$COPYRIGHT" ]] || { printf "$FILE:1:1: error: missing or malformed copyright notice\n" >> error-log.txt; }
done < <([[ $O2_CHECKCODE_CHANGEDFILES ]] && echo "$O2_CHECKCODE_CHANGEDFILES" | tr ':' '\n' \
                                          || (cd "$O2_SRC"; find . -name '*.cxx' -o -name '*.h'))

# Tell user what to do in case of copyright notice error
if grep -q "malformed copyright notice" error-log.txt; then
  printf "\nerror: Some files are missing the correct copyright notice on top.\n"
  printf "error: Make sure all your source files begin with the following exact lines:\nerror:\n"
  while read LINE; do printf "error: $LINE\n"; done < <(echo "$COPYRIGHT")
  printf "error:\nerror: List of non-compliant files will follow.\n\n"
fi

# Show only errors from the log, break in case some were found
echo ; echo ; echo "========== List of errors found =========="
GRERR=0
grep -v clang-diagnostic-error error-log.txt | grep " error:"   || GRERR=$?
[[ $GRERR == 0 ]] && exit 1

# Dummy modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
cat > $INSTALLROOT/etc/modulefiles/$PKGNAME <<EoF
#%Module1.0
proc ModulesHelp { } {
  global version
  puts stderr "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
}
set version $PKGVERSION-@@PKGREVISION@$PKGHASH@@
module-whatis "ALICE Modulefile for $PKGNAME $PKGVERSION-@@PKGREVISION@$PKGHASH@@"
# Dependencies
module load BASE/1.0 O2/$O2_VERSION-$O2_REVISION
# Our environment
set O2CHECKCODE_ROOT \$::env(BASEDIR)/$PKGNAME/\$version
setenv O2CHECKCODE_ROOT \$O2CHECKCODE_ROOT
EoF
