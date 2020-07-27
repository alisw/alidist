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
    tag: v5-09-20fb
  AliPhysics:
    version: "%(tag_basename)s"
    tag: v5-09-20fb-01

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
  # Use VMC packages compatible with ROOT 5
  GEANT3:
    version: "v2-7-p2"
    tag: "v2-7-p2"
  GEANT4_VMC:
    version: "v3-6-p6-inclxx-biasing-p5"
    tag: "v3-6-p6-inclxx-biasing-p5"
  GEANT4:
    source: https://github.com/alisw/geant4.git
    version: "v10.4.2-alice3"
    tag: "v10.4.2-alice3"
  vgm:
    version: "v4-4"
    tag: "v4-4"

  # ROOT 5 requires GSL < 2
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116) || (GSL_V >= 200)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included) and 2.00 (excluded)\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null

  # Minimal boost with no Python & co.
  boost:
    requires:
      - "GCC-Toolchain:(?!osx)"

---
