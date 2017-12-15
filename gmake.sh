package: gmake
version: "1.0"
system_requirement_missing: "Please install gmake or create a soft link on GNU systems where make is probably gmake"
system_requirement: ".*"
system_requirement_check: |
  which gmake >> /dev/null
---
