package: moderncppkafka
version: "%(tag_basename)s"
tag: v2023.03.07
requires:
  - librdkafka
source: https://github.com/morganstanley/modern-cpp-kafka.git
---

# this is header only library, so we can just copy it

mkdir -p $INSTALLROOT
cp -r $SOURCEDIR/include $INSTALLROOT/include
