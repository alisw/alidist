package: alpaka
version: "%(short_hash)s"
tag: 2fa91a34ed11b2076e474c5507d920e85cf9b79d
source: https://github.com/alpaka-group/alpaka.git
license: MPL-2.0
build_requires:
  - alibuild-recipe-tools
---
#!/bin/bash -e
mkdir -p "$INSTALLROOT/include" etc/modulefiles "$INSTALLROOT/etc/modulefiles"
rsync -a "$SOURCEDIR/include/" "$INSTALLROOT/include/"
alibuild-generate-module > "etc/modulefiles/$PKGNAME"
printf '\nsetenv ALPAKA_ROOT $::env(BASEDIR)/alpaka/$version\n' >> "etc/modulefiles/$PKGNAME"
rsync -a etc/modulefiles/ "$INSTALLROOT/etc/modulefiles/"
