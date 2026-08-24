package: IgProf
version: v6.0.0
tag: v6.0.0
source: http://github.com/igprof/igprof.git
requires:
  - libunwind
license: GPL-2.0
build_requires:
  - CMake
  - ninja
  - alibuild-recipe-tools
---
#!/bin/sh

cmake $SOURCEDIR \
      -G Ninja \
      -DCMAKE_INSTALL_PREFIX=$INSTALLROOT \
      -DUNWIND_INCLUDE_DIR=$LIBUNWIND_ROOT/include \
      -DUNWIND_LIBRARY=$LIBUNWIND_ROOT/lib/libunwind.so \
      -DCMAKE_CXX_FLAGS_RELWITHDEBINFO="-g -O3 -U_FORTIFY_SOURCE -Wno-attributes -Wno-pedantic"
cmake --build . -- ${JOBS:+-j$JOBS} install

# Modulefiles
mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
alibuild-generate-module --bin --lib > etc/modulefiles/${PKGNAME}Memory
alibuild-generate-module --bin --lib > etc/modulefiles/${PKGNAME}CPU

# The two extra modulefiles arm the profiler itself: loading one of them makes
# every program subsequently started in the environment run under IgProf,
# without having to wrap it in `igprof ...` -- which is what you want for a DPL
# pipeline, whose processes are spawned by the driver rather than from the
# command line.
#
# No igprof:out= is set on purpose: with an empty output spec IgProf builds its
# own per-process name, igprof.<progname>.<pid>.<time>.gz, so the devices of a
# workflow do not clobber each other's profile.
#
# Extra IgProf options can be appended before loading, e.g.
#   export IGPROF_OPTIONS=":real"            (CPU)
#   export IGPROF_OPTIONS=":overhead=delta"  (memory)

cat <<'EOF' >> etc/modulefiles/${PKGNAME}CPU

# --- IgProf performance (CPU) profiler ---
module-whatis "Runs everything started in this environment under the IgProf performance (CPU) profiler"
if { [info exists ::env(IGPROF_OPTIONS)] } {
  setenv IGPROF "perf$::env(IGPROF_OPTIONS)"
} else {
  setenv IGPROF "perf"
}
if { [uname sysname] == "Darwin" } {
  prepend-path DYLD_INSERT_LIBRARIES $PKG_ROOT/lib/libigprof.dylib
} else {
  prepend-path LD_PRELOAD $PKG_ROOT/lib/libigprof.so
}
EOF

cat <<'EOF' >> etc/modulefiles/${PKGNAME}Memory

# --- IgProf memory profiler ---
module-whatis "Runs everything started in this environment under the IgProf memory profiler"
if { [info exists ::env(IGPROF_OPTIONS)] } {
  setenv IGPROF "mem$::env(IGPROF_OPTIONS)"
} else {
  setenv IGPROF "mem"
}
if { [uname sysname] == "Darwin" } {
  prepend-path DYLD_INSERT_LIBRARIES $PKG_ROOT/lib/libigprof.dylib
} else {
  prepend-path LD_PRELOAD $PKG_ROOT/lib/libigprof.so
}
EOF

mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
