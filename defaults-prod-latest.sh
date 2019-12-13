package: defaults-prod-latest
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
disable:
  - RooUnfold
  - treelite
overrides:

  # Pinpoint AliRoot/AliPhysics
  AliRoot:
    version: "%(tag_basename)s"
    tag: v5-09-52
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-52-01

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
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116) || (GSL_V >= 200)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included) and 2.00 (excluded)\"\n#endif\nint main(){}" | c++ -I$(brew --prefix gsl)/include -xc++ - -o /dev/null

  # Minimal boost with no Python & co.
  boost:
    requires:
      - "GCC-Toolchain:(?!osx)"

---
