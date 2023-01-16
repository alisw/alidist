package: GEANT-VMC-test
version: "%(year)s%(month)s%(day)s"
force_rebuild: true
requires:
  - GEANT4_VMC
  - geant3_vmc-examples
---
#!/bin/bash -e

g3vmc_testE01
g3vmc_testE02
g3vmc_testE03
g3vmc_testE06
g3vmc_exampleE01
g3vmc_exampleE02
g3vmc_exampleE03
g3vmc_exampleE06

#g4root_OpNovice
#g4vmc_exampleE01
#g4vmc_exampleE02
#g4vmc_exampleE03
#g4vmc_exampleE06
#g4vmc_testE01
#g4vmc_testE02
#g4vmc_testE03
#g4vmc_testE06
