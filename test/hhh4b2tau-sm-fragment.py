import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
    args = cms.vstring('/cvmfs/cms.cern.ch/phys_generator/gridpacks/RunIII/13p6TeV/slc7_amd64_gcc10/MadGraph5_aMCatNLO/GF_HHH_c3_0_d4_0_slc7_amd64_gcc10_CMSSW_12_4_8_tarball.tar.xz'),
    nEvents = cms.untracked.uint32(5000),
    generateConcurrently = cms.untracked.bool(True),
    numberOfParameters = cms.uint32(1),
    outputFile = cms.string('cmsgrid_final.lhe'),
    scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh')
)

#Link to datacards:
#https://github.com/cms-sw/genproductions/tree/master/bin/MadGraph5_aMCatNLO/cards/production/13p6TeV/Higgs/GF_HHH/GF_HHH_c3_0_d4_0

import FWCore.ParameterSet.Config as cms
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunesRun3ECM13p6TeV.PythiaCP5Settings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *
from Configuration.Generator.Pythia8aMCatNLOSettings_cfi import *

generator = cms.EDFilter("Pythia8ConcurrentHadronizerFilter",
	maxEventsToPrint = cms.untracked.int32(1),
	pythiaPylistVerbosity = cms.untracked.int32(1),
	filterEfficiency = cms.untracked.double(1.0),
	pythiaHepMCVerbosity = cms.untracked.bool(False),
	comEnergy = cms.double(13600.),
	PythiaParameters = cms.PSet(
	pythia8CommonSettingsBlock,
	pythia8CP5SettingsBlock,
	pythia8PSweightsSettingsBlock,
	pythia8aMCatNLOSettingsBlock,
  	processParameters = cms.vstring(
            '25:m0 = 125.0',
            '25:onMode = off',
            '25:onIfMatch = 5 -5', #H decay to b
            '25:onIfMatch = 15 -15', #H decay to tau
            'ResonanceDecayFilter:filter = on',
            'ResonanceDecayFilter:exclusive = on', #off: require at least the specified number of daughters, on: require exactly the specified number of daughters
            'ResonanceDecayFilter:mothers = 25', #list of mothers not specified -> count all particles in hard process+resonance decays (better to avoid specifying mothers when including leptons from the lhe in counting, since intermediate resonances are not gauranteed to appear in general
            'ResonanceDecayFilter:daughters = 5,5,5,5,15,15',
  ),
	parameterSets = cms.vstring('pythia8CommonSettings',
		'pythia8CP5Settings',
		'pythia8PSweightsSettings',
		'pythia8aMCatNLOSettings',
		'processParameters',
	)
  )
)

ProductionFilterSequence = cms.Sequence(generator)