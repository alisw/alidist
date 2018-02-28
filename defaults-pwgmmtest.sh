package: defaults-pwgmmtest
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++11"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
overrides:
# taken from defaults-root6
  GCC-Toolchain:
    tag: v6.2.0-alice1
    prefer_system_check: |
      set -e
      which gfortran || { echo "gfortran missing"; exit 1; }
      which cc && test -f $(dirname $(which cc))/c++ && printf "#define GCCVER ((__GNUC__ << 16)+(__GNUC_MINOR__ << 8)+(__GNUC_PATCHLEVEL__))\n#if (GCCVER < 0x060200)\n#error \"System's GCC cannot be used: we need at least GCC 6.X. We are going to compile our own version.\"\n#endif\n" | cc -xc++ - -c -o /dev/null
  ROOT:
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
      - libpng
      - lzma
  GSL:
    prefer_system_check: |
      printf "#include \"gsl/gsl_version.h\"\n#define GSL_V GSL_MAJOR_VERSION * 100 + GSL_MINOR_VERSION\n# if (GSL_V < 116)\n#error \"Cannot use system's gsl. Notice we only support versions from 1.16 (included)\"\n#endif\nint main(){}" | gcc  -I$(brew --prefix gsl)/include -xc++ - -o /dev/null
  AliRoot:
    version: "%(commit_hash)s_PWGMMTEST"
    tag: v5-09-22
  AliPhysics:
    version: "%(commit_hash)s_PWGMMTEST"
    tag: v5-09-22-01
# now for actual generators
  agile:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/agile
  aligenerators:
    version: "v%(year)s%(month)s%(day)s_PWGMMTEST"
  aligenmc:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/aligenmc
  ampt:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/ampt
  crmc:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/crmc
  dpmjet:
    version: "%(tag_basename)s_PWGMMTEST"
  herwig:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/herwig
  jewel:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/jewel
  lhapdf:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/lhapdf
  powheg:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/powheg
  pythia6:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/pythia6
  pythia:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/pythia8
  rivet:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/rivet
  rivet-hi:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/rivet-hi
  sacrifice:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/sacrifice
  sherpa:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/sherpa
  thepeg:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/thepeg
  therminator2:
    version: "%(tag_basename)s_PWGMMTEST"
    source: https://github.com/alipwgmm/therminator
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.
