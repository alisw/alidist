package: golang
version: "1.22.2"
build_requires:
  - curl
  - alibuild-recipe-tools
prefer_system: ".*"
prefer_system_check: |
  type go && case `go version | sed -e 's/go version go//' | sed -e 's/ .*//'` in 1.2[2-9].*) exit 0 ;; *) exit 1 ;; esac
---
case $ARCHITECTURE in
  osx_arm64) ARCH=$(uname|tr '[:upper:]' '[:lower:]')-arm64 ;;
  *_aarch64) ARCH=$(uname|tr '[:upper:]' '[:lower:]')-arm64 ;;
  *) ARCH=$(uname|tr '[:upper:]' '[:lower:]')-amd64 ;;
esac
curl -LO https://golang.org/dl/go$PKGVERSION.$ARCH.tar.gz
tar --strip-components=1 -C $INSTALLROOT -xzf go$PKGVERSION.$ARCH.tar.gz

mkdir -p etc/modulefiles
alibuild-generate-module --bin --lib > etc/modulefiles/$PKGNAME
mkdir -p $INSTALLROOT/etc/modulefiles && rsync -a --delete etc/modulefiles/ $INSTALLROOT/etc/modulefiles
