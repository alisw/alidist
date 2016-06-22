package: defaults-daq
version: v1
env:
  CXXFLAGS: "-fPIC -g -O2 -std=c++98"
  CFLAGS: "-fPIC -g -O2"
  CMAKE_BUILD_TYPE: "RELWITHDEBINFO"
  ALICE_DAQ: "1"
  AMORE_CONFIG: /opt/amore/bin/amore-config
  DATE_CONFIG: /opt/date/.commonScripts/date-config
  DATE_ENV: /date/setup.sh
  DAQ_DIM: /opt/dim
  DAQ_DALIB: /opt/daqDA-lib
---
#!/bin/bash -e
for PKG in date amore daqDA-lib ACT; do
  yum info $PKG
done
