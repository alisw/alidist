package: Python-system
version: "1.0"
system_requirement_missing: |
  Python 2.7+ and pip are required for this installation. Please make sure they are installed.
  You will also need the development packages (usually called python-dev or python-devel).

  Please also make sure you have the following Python modules, which can be installed via pip:

    - matplotlib
    - numpy
    - certifi
    - ipython
    - ipywidgets
    - ipykernel
    - notebook
    - metakernel
    - pyyaml
system_requirement: ".*"
system_requirement_check: |
  python -c 'import sys; import sqlite3; sys.exit(1 if sys.version_info < (2, 7) else 0)' && pip --help > /dev/null && printf '#include "pyconfig.h"' | cc -c -I$(python-config --includes) -xc -o /dev/null - && python -c 'import matplotlib,numpy,certifi,IPython,ipywidgets,ipykernel,notebook.notebookapp,metakernel,yaml'
---
