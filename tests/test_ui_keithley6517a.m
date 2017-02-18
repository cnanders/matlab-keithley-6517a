[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add package and libs
addpath(genpath(fullfile(cDirThis, '..')));

purge

ui = TestUiKeithley6517a();
ui.build();