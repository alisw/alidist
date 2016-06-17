package: DAQ
version: v1
prefer_system: slc6.*
prefer_system_check: |
  ! rpm -q date amore daqDA-lib ACT
---
#!/bin/bash -e
# This is a dummy recipe used to track DAQ dependencies installed via RPMs.
# AliRoot depends on it and will be rebuilt if this package's version changes.
# For DAQ use: prefer_system_check returns 1 in order to force the creation of
# this dummy package. For all the other use cases: prefer_system_check returns 0
# and this dependency will be silently ignored.
