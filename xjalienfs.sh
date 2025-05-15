package: xjalienfs
version: "%(tag_basename)s"
tag: "1.6.6"
source: https://gitlab.cern.ch/jalien/xjalienfs.git
requires:
  - "OpenSSL:(?!osx)"
  - "osx-system-openssl:(osx.*)"
  - XRootD
  - AliEn-Runtime
  - Python-modules
build_requires:
  - alibuild-recipe-tools
prepend_path:
  PYTHONPATH: ${XJALIENFS_ROOT}/lib/python/site-packages
prefer_system: ".*"
prefer_system_check: |
  # if we are in a virtualenv, assume people know what they are doing
  # and simply use the virtualenv recipe.
  if [ ! -z $VIRTUAL_ENV ]; then
    echo "alibuild_system_replace: virtualenv"
    exit 0
  fi
  # If not, either they are using the system python or they are using our own python.
  # In both cases we can simply create our own virtualenv
  exit 1
prefer_system_replacement_specs:
  virtualenv:
    recipe: |
      #!/bin/bash -e

      # Use pip's --target to install under $INSTALLROOT without weird hacks. This
      # works inside and outside a virtualenv, but unset VIRTUAL_ENV to make sure we
      # only depend on stuff we installed using our Python and Python-modules.

      # on macos try to install gnureadline and just skip if fails (alienpy can work without it)
      # macos python readline implementation is build on libedit which does not work
      [[ "$ARCHITECTURE" ==  osx_* ]] && { \
          python3 -m pip install --force-reinstall \
          gnureadline || : ; }

      env ALIBUILD=1 \
          python3 -m pip install --force-reinstall \
          "git+https://gitlab.cern.ch/jalien/xjalienfs.git@$PKG_VERSION"
      # We do not need anything else, because python is going to be in path
      # if we are inside a virtualenv so no need to pretend we know where
      # the correct python is.

      # We generate the modulefile to avoid complains by dependencies
      mkdir -p "$INSTALLROOT/etc/modulefiles"
      alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
    requires:
      - XRootD
      - AliEn-Runtime
    build_requires:
      - alibuild-recipe-tools
---
#!/bin/bash -e

# Use pip's --target to install under $INSTALLROOT without weird hacks. This
# works inside and outside a virtualenv, but unset VIRTUAL_ENV to make sure we
# only depend on stuff we installed using our Python and Python-modules.

env -u VIRTUAL_ENV ALIBUILD=1 \
    python3 -m pip install --force-reinstall \
    --target="$INSTALLROOT/lib/python/site-packages" \
    "file://$SOURCEDIR"

# Make sure all the tools use the correct python
# By default, pip install --target installs binaries inside the given target dir
# as well, but we want them directly under $INSTALLROOT/bin instead.
rm -rf "${INSTALLROOT:?}/bin"
mv "$INSTALLROOT/lib/python/site-packages/bin" "$INSTALLROOT/bin"
for binfile in "$INSTALLROOT"/bin/*; do
  [ -f "$binfile" ] || continue
  if grep -q "^'''exec' .*python.*" "$binfile"; then
    # This file uses a hack to get around shebang size limits. As we're
    # replacing the shebang with the system python, the limit doesn't apply and
    # we can just use a normal shebang.
    sed -i.bak '1d; 2d; 3d; 4s,^,#!/usr/bin/env python3\n,' "$binfile"
  else
    sed -i.bak '1s,^#!.*python.*,#!/usr/bin/env python3,' "$binfile"
  fi
done
rm -fv "$INSTALLROOT"/bin/*.bak

# Now that alien.py is installed, we can run its tests.
set +x   # avoid echoing tokens
# Make sure we don't accidentally run read-write tests with users' JAliEn keys.
if [ -n "$ALIBUILD_XJALIENFS_TESTS" ] &&
     # Tests need a JAliEn token, so skip them if we have none.
     [ -n "$JALIEN_TOKEN_CERT" ] && [ -n "$JALIEN_TOKEN_KEY" ]
then
  # temporary measure againt breakage of alienpy tests on Alma9 aarch64 builder environment
  # the breakage is present only in the special CI environment on that machine
  [[ "${ARCHITECTURE}" != "slc9_aarch64" ]] && PATH="$INSTALLROOT/bin:$PATH" \
  PYTHONPATH="$INSTALLROOT/lib/python/site-packages:$PYTHONPATH" \
  "$SOURCEDIR/tests/run_tests" ci-tests
fi
set -x

# Modulefile
mkdir -p "$INSTALLROOT/etc/modulefiles"
alibuild-generate-module --bin > "$INSTALLROOT/etc/modulefiles/$PKGNAME"
cat <<\EOF >> "$INSTALLROOT/etc/modulefiles/$PKGNAME"
prepend-path PYTHONPATH $PKG_ROOT/lib/python/site-packages
EOF
