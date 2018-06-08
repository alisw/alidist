package: defaults-jalien
version: v1
overrides:
  xrootd:
    version: "%(tag_basename)s"
    tag: "v4.8.3"
    source: https://github.com/xrootd/xrootd
---
# This file is included in any build recipe and it's only used to set
# environment variables. Which file to actually include can be defined by the
# "--defaults" option of alibuild.

