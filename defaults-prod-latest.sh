disable:
- RooUnfold
- treelite
env:
  CFLAGS: -fPIC -g -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -g -O2 -std=c++11
overrides:
  AliPhysics:
    tag: vAN-20210821
    version: '%(tag_basename)s'
  AliRoot:
    requires:
    - ROOT
    - DPMJET
    - fastjet:(?!.*ppc64)
    - GEANT3
    - GEANT4_VMC
    - Vc
    - AliEn-ROOT-Legacy
    tag: v5-09-57g
    version: '%(tag_basename)s'
  Alice-GRID-Utils:
    tag: 0.0.6
    version: '%(tag_basename)s'
  GEANT3:
    tag: v2-7-p2
    version: v2-7-p2
  GEANT4:
    tag: v10.4.2
    version: v10.4.2
  GEANT4_VMC:
    requires:
    - GEANT4
    - vgm
    tag: v3-6-p6-inclxx-biasing-p2
    version: v3-6-p6-inclxx-biasing-p2
  GSL:
    prefer_system_check: 'printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION
      * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116) || (GSL_V >= 200)\n#error \"Cannot
      use system''s gsl. Notice we only support versions from 1.16 (included) and
      2.00 (excluded)\"\n#endif\nint main(){}" | c++ -I$(brew --prefix gsl)/include
      -xc++ - -o /dev/null

      '
  ROOT:
    build_requires:
    - CMake
    - Xcode:(osx.*)
    requires:
    - AliEn-Runtime:(?!.*ppc64)
    - GSL
    - opengl:(?!osx)
    - Xdevel:(?!osx)
    - FreeType:(?!osx)
    - MySQL:slc7.*
    - GCC-Toolchain:(?!osx)
    - XRootD
    source: https://github.com/alisw/root
    tag: v5-34-30-alice10
  XRootD:
    source: https://github.com/alisw/xrootd.git
    tag: v3.3.6-alice2
  boost:
    requires:
    - GCC-Toolchain:(?!osx)
  vgm:
    tag: v4-4
    version: v4-4
package: defaults-prod-latest
version: v1

---
