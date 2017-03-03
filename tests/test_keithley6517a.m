[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add package
addpath(genpath(fullfile(cDirThis, '..', 'pkg')));

inst = keithley.keithley6517a.Keithley6517a('lSerial', true);

inst.init()
inst.connect()
inst.setFunctionToAmps();

cIdentity = inst.identity()

return

inst.setIntegrationPeriod(100e-3)
dPeriod = inst.getIntegrationPeriod()

inst.setAverageState('ON')
cAverageState = inst.getAverageState()

inst.setAverageCount(12)
u8AverageCount = inst.getAverageCount()

inst.setAverageMode('MOVING')
cAverageMode = inst.getAverageMode()

inst.setRange(20e-6)
dRange = inst.getRange()

inst.setAverageType('NONE')
cAverageType = inst.getAverageType()


inst.setMedianState('OFF')
inst.setMedianRank(3)

cMedianState = inst.getMedianState()
u8MedianRank = inst.getMedianRank()

