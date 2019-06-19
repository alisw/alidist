package: defaults-pwgmmtest
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
  ROOT:
    version: "%(tag_basename)s_PWGMMTEST"
    tag: "v6-16-00"
    source: https://github.com/root-mirror/root
    requires:
      - AliEn-Runtime:(?!.*ppc64)
      - GSL
      - opengl:(?!osx)
      - Xdevel:(?!osx)
      - FreeType:(?!osx)
      - Python-modules
      - "GCC-Toolchain:(?!osx)"
      - libpng
      - lzma
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included)\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null
  AliRoot:
    version: "%(commit_hash)s_PWGMMTEST"
    tag: v5-09-49
  AliPhysics:
    version: "%(commit_hash)s_PWGMMTEST"
    tag: v5-09-49-01
  AGILe:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/agile
  AliGenerators:
    version: "v%(year)s%(month)s%(day)s_PWGMMTEST"
  aligenmc:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/aligenmc
  AMPT:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/ampt
  CRMC:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/crmc
  DPMJET:
    version: "%(tag_basename)s_PWGMMTEST"
  EPOS:
    version: "%(tag_basename)s_PWGMMTEST"
  Herwig:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/herwig
  JEWEL:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/jewel
  lhapdf:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/lhapdf
  lhapdf-pdfsets:
    version: "v%(year)s%(month)s%(day)s_PWGMMTEST"
  POWHEG:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/powheg
  pythia6:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/pythia6
  pythia:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/pythia8
  Rivet:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/rivet
  Rivet-hi:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/rivet-hi
  Sacrifice:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/sacrifice
  SHERPA:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/sherpa
  ThePEG:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/thepeg
  Therminator2:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/therminator
  YODA:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/yoda
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
