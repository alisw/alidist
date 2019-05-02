package: Python-system
version: "3.6"
system_requirement_missing: |
  Python 3.6 is missing from your system. We need the python3 and pip3 executables in the PATH.
  It can be installed with:
   * brew install python3
system_requirement: ".*"
system_requirement_check: |
  python3 -c 'import sys; import sqlite3; sys.exit(1 if sys.version_info < (3,6) else 0)' && pip3 help
---
