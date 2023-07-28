package: defaults-user
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
disable:
  - DPMJET
  - GEANT3
  - GEANT4
  - GEANT4_VMC
  - RooUnfold
  - treelite
overrides:
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-56v
    requires:
      - ROOT
      - DPMJET
      - fastjet:(?!.*ppc64)
      - GEANT3
      - GEANT4_VMC
      - Vc
      - AliEn-ROOT-Legacy
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-56v-01
  XRootD:
    tag: v3.3.6-alice2
    source: https://github.com/alisw/xrootd.git

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
      - XRootD
    build_requires:
      - CMake
      - "Xcode:(osx.*)"

  # ROOT 5 requires GSL < 2
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116) || (GSL_V >= 200)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included) and 2.00 (excluded)\"\n#endif\nint main(){}" | c++  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null

  # Minimal boost with no Python & co.
  boost:
    requires:
      - "GCC-Toolchain:(?!osx)"
---
# To be used with aliBuild option `--defaults user`.
#
# This defaults set is meant to be used on user computers.
#
#   * Builds AliRoot and AliPhysics without GEANT3, 4 and DPMJET, which fits
#     most of the use cases and speeds up compilation time dramatically
#   * Pinpoints AliRoot and AliPhysics to their latest tags, but they will be
#     overridden by using packages in development mode
#
# This defaults set will become the default and will replace "release" at some
# point.
