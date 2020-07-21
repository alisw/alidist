package: defaults-user
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-02h
    requires:
      - ROOT
      - fastjet:(?!.*ppc64)
      - Vc
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-02h-01
  ROOT:
    version: "%(tag_basename)s"
    version: "%(tag_basename)s"
    tag: "v6-10-08"
    source: https://github.com/root-mirror/root
    requires:
      - AliEn-Runtime:(?!.*ppc64)
      - GSL
      - opengl:(?!osx)
      - Xdevel:(?!osx)
      - FreeType:(?!osx)
      - Python-modules
      - "GCC-Toolchain:(?!osx)"
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included)\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null
---
# To be used with aliBuild option `--defaults user-root6`.
#
# This defaults set is meant to be used on user computers with ROOT 6 as a base.
#
#   * Builds AliRoot and AliPhysics without GEANT3, 4 and DPMJET, which fits
#     most of the use cases and speeds up compilation time dramatically
#   * Pinpoints AliRoot and AliPhysics to their latest tags, but they will be
#     overridden by using packages in development mode
#
# This defaults set will become the default and will replace "release" at some
# point.
