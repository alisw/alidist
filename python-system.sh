package: Python-system
version: "3.6"
system_requirement_missing: |
  Python 3.6 is missing from your system. We need the python3 and pip3 executables in the PATH.
  It can be installed with:
   * On Ubuntu: sudo apt-get install python3 python3-pip python3-tk
   * On macOS: brew install python3
system_requirement: ".*"
system_requirement_check: |
  python3 -c 'import sys; import sqlite3; sys.exit(1 if sys.version_info < (3,5) else 0)'
---
