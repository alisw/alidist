package: O2Physics-code-check
version: "1.0"
requires:
  - O2Physics
  - Clang:(?!osx*)
license: GPL-3.0
force_rebuild: true
---
#!/bin/bash -e

# Runs checks on the O2Physics codebase.

set -euo pipefail

# Verify Clang.
[[ -d "$CLANG_ROOT" ]]

# Get the compilation database from the O2Physics build dir.
O2PHYSICS_BUILDDIR="$(realpath ${BUILDDIR}/../../O2Physics-latest/O2Physics)"
cp "${O2PHYSICS_BUILDDIR}/compile_commands.json" .

# Guess the source directory as the common path of .cxx files in the compilation database.
O2PHYSICS_SRC=$(python3 -c 'import json, os; print(os.path.commonpath([x["file"] for x in json.loads(open("compile_commands.json").read()) if "sw/BUILD" not in x["file"] and "G__" not in x["file"] and x["file"].endswith(".cxx")]))')
pushd "$O2PHYSICS_SRC"
[[ -e "CMakeLists.txt" ]]
[[ -d ".git" ]]

# If a base Git commit is provided, get a list of existing C++ files changed since.
# If base Git commit is not provided, get all tracked C++ files.
if [[ -n "${ALIBUILD_BASE_HASH:-}" ]]; then
  FILES=$(git diff --diff-filter=d --name-only "$ALIBUILD_BASE_HASH${ALIBUILD_HEAD_HASH:+...$ALIBUILD_HEAD_HASH}")
else
  FILES=$(git ls-files)
fi
# Keep only existing C++ files.
FILES_TO_CHECK=()
while IFS= read -r FILE; do
  case "$FILE" in
    *.cxx|*.h|*.C)
      [[ -e "$FILE" ]] && FILES_TO_CHECK+=("$FILE")
      ;;
  esac
done <<< "$FILES"
# Abort if no files to check.
if [[ ${#FILES_TO_CHECK[@]} -eq 0 ]]; then
  echo "Nothing to check."
  exit 0
fi

# Run checks on selected files.
# Run clang-tidy and parallelise with xargs.
# We cannot use run-clang-tidy, because it ignores anything missing in the compilation database (headers, macros).
LOGFILE="${BUILDDIR}/error-log.txt"
CLANG_TIDY="${CLANG_ROOT}/bin-safe/clang-tidy"
[[ -e .clang-tidy ]] && echo "Found configuration file: $O2PHYSICS_SRC/.clang-tidy"
echo "Additional checks on command line: \"${O2PHYSICS_CHECKER_CHECKS=""}\""
"$CLANG_TIDY" --list-checks --checks="$O2PHYSICS_CHECKER_CHECKS"
printf "%s\n" "${FILES_TO_CHECK[@]}" | xargs -r ${JOBS+-P $JOBS} -I{} \
  "$CLANG_TIDY" --checks="$O2PHYSICS_CHECKER_CHECKS" ${O2PHYSICS_CHECKER_FIX:+-fix} "{}" 2>&1 | tee "$LOGFILE" || true
[[ -f "$LOGFILE" ]]

# If issues were found, report them and abort.
# Consider only issues in the O2Physics files.
echo -e "\n\n========== List of errors found =========="
if grep -qE "^${O2PHYSICS_SRC}/.+: (warning|error): " "$LOGFILE"; then
  grep -E "^${O2PHYSICS_SRC}/.+: (warning|error): " "$LOGFILE" | sed -e "s,${O2PHYSICS_SRC}/,,g" | sort -V | uniq
  exit 1
fi

popd

# Dummy modulefile
mkdir -p $INSTALLROOT/etc/modulefiles
alibuild-generate-module > $INSTALLROOT/etc/modulefiles/$PKGNAME
