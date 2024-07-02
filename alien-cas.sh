package: AliEn-CAs
version: v1
tag: f62625ede780d455b3b7878064bcfee6bd9a4f53
source: https://github.com/alisw/alien-cas.git
prefer_system: .*
prefer_system_check: |
  # If we can verify the user's cert, the CERN CA must be installed
  # system-wide. In that case, don't install our certs.
  openssl verify ~/.globus/usercert.pem > /dev/null 2> /dev/null
build_requires:
  - alibuild-recipe-tools
env:
  # This is only used for O2/O2Physics unit tests. These are run
  # locally (in which case these CAs are fine and assumed to be
  # up-to-date) or in CI (ditto).
  X509_CERT_DIR: "$ALIEN_CAS_ROOT/globus/share/certificates"
---
#!/bin/bash -e
DEST="$INSTALLROOT/globus/share/certificates"
mkdir -p "$DEST"
find "$SOURCEDIR" -type d -maxdepth 1 -mindepth 1 -exec rsync -av {}/ "$DEST" \;

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"
alibuild-generate-module > "$MODULEFILE"
cat >> "$MODULEFILE" <<EOF
try {
  exec openssl verify \$::env(HOME)/.globus/usercert.pem > /dev/null 2> /dev/null
} trap CHILDSTATUS {} {
  # If we couldn't validate the user's cert, either it doesn't exist
  # or the CERN CA isn't installed as a system cert. In the latter
  # case, we should redirect to CVMFS or to our certs.
  if [file isdirectory /cvmfs/alice.cern.ch/etc/grid-security/certificates] {
    # Prefer current certs from CVMFS, if available. This avoids
    # failures due to expired certs.
    setenv X509_CERT_DIR /cvmfs/alice.cern.ch/etc/grid-security/certificates
  } else {
    # As a fallback, use the certs we installed. Fine for local dev and CI.
    setenv X509_CERT_DIR \$::env(BASEDIR)/AliEn-CAs/\$version/globus/share/certificates
  }
}
EOF
