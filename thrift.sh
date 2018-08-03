package: thrift
version: "%(tag_basename)s"
tag: 0.9.3
source: https://git-wip-us.apache.org/repos/asf/thrift.git
build_requires:
 - "GCC-Toolchain:(?!osx)"
system_requirement: ".*"
system_requirement_check: |
  thrift --version
---
