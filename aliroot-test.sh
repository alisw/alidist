package: aliroot-test
version: v1
requires:
  - aliroot
---
#!/bin/sh
aliroot -b BUILD/slc7-x86_64/aliroot/v5-06-28-1/aliroot/test/gun/sim.C
