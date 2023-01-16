package: EPOS-test
version: v1
force_rebuild: true
requires:
  - EPOS
---
#!/bin/bash -e
export OPT=$PWD
export CHK=$PWD
cp "$EPO"/test/bp5nohnoc10n10f.optns .
cp "$EPO"/test/iclbp.optns .
epos bp5nohnoc10n10f
[ -f z-bp5nohnoc10n10f.root ]
