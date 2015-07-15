package: alien
version: v1
prepend_path:
  - "LD_LIBRARY_PATH": "$ALIEN_ROOT/alien/api/lib"
  - "DYLD_LIBRARY_PATH": "$ALIEN_ROOT/alien/api/lib"
  - "PATH": "$ALIEN_ROOT/alien/api/bin"
requires:
  - GCC
  - Binutils
---
#!/bin/sh
curl -O -fSsL --insecure http://alien.cern.ch/alien-installer
chmod +x alien-installer
./alien-installer -install-dir "$INSTALLROOT/alien" -batch -notorrent -type compile -no-certificate-check
