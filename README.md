# About

MATLAB class for serial / GPIB communication with a Keithley 6517A.  This class only implements part of the API that the hardware exposes. There is an optional user interface that requires the [github/cnanders/mic](https://github.com/cnanders/mic) UI library

# Requirements

MATLAB Instrument Control Toolbox (only required for `gpib` communications; `serial` communication does not require the toolbox)

# Dependencies

[github/cnanders/mic](https://github.com/cnanders/mic) (for the UI)