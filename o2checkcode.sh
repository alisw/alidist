package: o2checkcode
version: "1.0"
requires:
  - O2
  - o2codechecker
license: GPL-3.0
build_requires:
  - CMake
  - alibuild-recipe-tools
force_rebuild: true
---
#!/bin/bash -e

# Runs a set of (selected) code checks on the O2 code-base. Assumes the
# compile_commands.json file is available under $O2_ROOT
cp "${O2_ROOT}"/compile_commands.json .

# We will try to setup a list of files to be checked by using 2 specific Git commits to compare

# Heuristically guess source directory

O2_SRC=$(python3 -c 'import json, os; print(os.path.commonpath([x["file"] for x in json.loads(open("compile_commands.json").read()) if "sw/BUILD" not in x["file"] and "G__" not in x["file"] and x["file"].endswith(".cxx")]))')
[[ -e "$O2_SRC"/CMakeLists.txt ]]

# We have something to compare our working directory to (ALIBUILD_BASE_HASH). We check only the
# changed files (including the untracked ones) if the list of relevant files that changed is up to
# 50 entries long
if [[ $ALIBUILD_BASE_HASH ]]; then
  pushd "$O2_SRC"
    [[ -d .git ]]
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
ThinCompilationsDatabase.py -exclude-files '(?:.*G\_\_.*\.cxx|.*\.pb.cc|.*\_amalgamated\..*|.*\.cu$|.*\.hip$)' ${O2_CHECKCODE_CHANGEDFILES:+-use-files ${O2_CHECKCODE_CHANGEDFILES}}
cp thinned_compile_commands.json compile_commands.json

# List of explicitely enabled C++ checks (make sure they are all green)
CHECKS="${O2_CHECKER_CHECKS:--*\
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
,-clang-diagnostic-vla-cxx-extension\
}"

echo $CHECKS
$CLANG_ROOT/bin-safe/clang-tidy --load $O2CODECHECKER_ROOT/lib/libclangTidyAliceO2Module.so --list-checks -checks="*"
# GCC installation of the toolchain O2 was compiled with
GCC_INSTALL_DIR=
if [[ $GCC_TOOLCHAIN_REVISION ]]; then
  GCC_INSTALL_DIR=$(find "$GCC_TOOLCHAIN_ROOT/lib" -name crtbegin.o -exec dirname {} \; | head -n1)
fi
# Run C++ checks. -Wno-error overrides the -Werror of PR builds, which would otherwise
# turn compiler warnings into errors that clang-tidy cannot filter out with -checks.
run_O2CodeChecker.py ${JOBS+-j $JOBS} \
	-clang-tidy-binary $CLANG_ROOT/bin-safe/clang-tidy \
	-clang-apply-replacements-binary "$CLANG_ROOT/bin-safe/clang-apply-replacements" \
  -extra-args="--load $O2CODECHECKER_ROOT/lib/libclangTidyAliceO2Module.so --extra-arg=-Wno-error${GCC_INSTALL_DIR:+ --extra-arg=--gcc-install-dir=$GCC_INSTALL_DIR}" \
	-header-filter='.*SOURCES(?!.*/3rdparty/).*' \
        ${O2_CHECKER_FIX:+-fix} -checks="$CHECKS" 2>&1 | tee error-log.txt

# Turn warnings into errors
sed -e 's/ warning:/ error:/g' error-log.txt > error-log.txt.0 && mv error-log.txt.0 error-log.txt

# Show only errors from the log, break in case some were found
echo ; echo ; echo "========== List of errors found =========="
# -a: the log can contain NUL bytes, which would make grep treat it as binary and print nothing
GRERR=0
grep -a -v clang-diagnostic-error error-log.txt | grep -a " error:"   || GRERR=$?
[[ $GRERR == 0 ]] && exit 1

# Dummy modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
