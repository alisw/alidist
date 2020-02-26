package: rsync
version: "1.0"
system_requirement_missing: |
  rsync is missing from your system.

  It can be installed with:
   * On Centos: sudo yum install rsync
   * On Ubuntu: sudo apt-get install rsync
system_requirement: ".*"
system_requirement_check: "rsync --version"
---
