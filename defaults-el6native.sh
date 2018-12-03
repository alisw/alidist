package: defaults-el6native
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++98"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  ALIROOT_ONLINE_MODE: "1"

disable:
  - AliEn-Runtime
  - GCC-Toolchain
  - Python-modules
  - Python
  - RooUnfold
  - treelite

overrides:
  AliRoot:
    requires:
      - ROOT
    build_requires:
      - CMake

  # Use ROOT 5
  ROOT:
    tag: v5-34-30-alice10
    source: https://github.com/alisw/root
    requires:
      - AliEn-Runtime:(?!.*ppc64)
      - GSL
      - opengl:(?!osx)
      - Xdevel:(?!osx)
      - FreeType:(?!osx)
      - "MySQL:slc7.*"
      - GCC-Toolchain:(?!osx)
    build_requires:
      - CMake
      - "Xcode:(osx.*)"

  # ROOT 5 requires GSL < 2
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116) || (GSL_V >= 200)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included) and 2.00 (excluded)\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null

  # Minimal boost with no Python & co.
  boost:
    requires:
      - "GCC-Toolchain:(?!osx)"
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
