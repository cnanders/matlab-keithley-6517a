if exist('purge') > 0
    purge
end

[cDirThis, cName, cExt] = fileparts(mfilename('fullpath'));

% Add package and libs
addpath(genpath(fullfile(cDirThis, '..', 'src')));

% Add cnanders/github/mic dependency (assumed one dir above)
addpath(genpath(fullfile(cDirThis, '..', '..', 'mic')));

ui = TestUiKeithley6517a();
ui.build();