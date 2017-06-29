package: AliRoot-guntest
version: v1
force_rebuild: 1
requires:
  - AliRoot
  - AliRoot-OCDB
---
#!/bin/bash -e

# A simple regression test launching a Geant3 + Geant4 gun simulation + reconstruction.
# Tests if the processing runs through and yields a reasonable ESD.
# Note that the test is limited to the default OCDB.
rsync -a "$ALIROOT_ROOT"/test/vmctest/gun test
cd test/gun

# launch the simulation
./runtest.sh

# test outcome and return the error code
WITHESDCHECK=${ALIPHYSICS_VERSION:+yes} ./finalcheck.sh
