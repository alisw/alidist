package: O2-customization
version: "v1.0.0"
env:
  ENABLE_UPGRADES: "ON"
valid_defaults:
  - o2
  - o2-dataflow
  - o2-epn
  - o2-dev-fairroot
  - alo
  - o2-prod
  - ali
---
# No contents. The only goal of this recipe is to provide customizations to
# enable / disable features of the O2 builds. This cannot be done in the O2
# recipe itself, because the "env" variables affect only dependencies.
