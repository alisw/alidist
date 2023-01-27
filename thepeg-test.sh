package: ThePEG-test
version: v1
force_rebuild: true
requires:
  - ThePEG
---
#!/bin/bash -e
cat > DIPSYpp_HepMC.in <<\EOF
read Tune27.in
cd /DIPSY
cp EventHandler LHCEventHandler
set LHCEventHandler:WFL stdProton
set LHCEventHandler:WFR stdProton
set LHCEventHandler:ConsistencyLevel 0
set LHCEventHandler:XSecFn:CheckOffShell false
set LHCEventHandler:CascadeHandler NULL
set LHCEventHandler:HadronizationHandler NULL
set LHCEventHandler:DecayHandler NULL
create ThePEG::FixedCMSLuminosity LHCLumi
set LHCEventHandler:LuminosityFunction LHCLumi
cp Generator LHCGenerator
set LHCGenerator:EventHandler LHCEventHandler
set LHCEventHandler:EffectivePartonMode Colours
set LHCGenerator:EventHandler:DecayHandler /Defaults/Handlers/StandardDecayHandler
set LHCGenerator:EventHandler:HadronizationHandler Frag8
set LHCEventHandler:WFL Proton
set LHCEventHandler:WFR Proton
set LHCEventHandler:EventFiller:SoftRemove NoValence
set LHCGenerator:EventHandler:LuminosityFunction:Energy 7000
create ThePEG::HepMCFile HepMCFile HepMCAnalysis.so
set LHCGenerator:AnalysisHandlers 0 HepMCFile
set HepMCFile:Filename DIPSYpp.hepmc
set HepMCFile:PrintEvent 10000000000
set HepMCFile:Format GenEvent
set HepMCFile:Units GeV_mm
saverun DIPSYpp LHCGenerator
EOF

setupThePEG -r $THEPEG_ROOT/lib/ThePEG/ThePEGDefaults.rpo \
            -I $THEPEG_ROOT/share/Ariadne \
            DIPSYpp_HepMC.in
runThePEG DIPSYpp.run -N100 --tics
