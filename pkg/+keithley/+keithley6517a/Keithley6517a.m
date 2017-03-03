classdef Keithley6517a < keithley.keithley6517a.AbstractKeithley6517a

    % Can only use ASCII format with RS232.  Need GPIB to use other formats
    
    properties (Constant)
        
        % Used for setting the data format of GPIB communications
        cDATA_FORMAT_IEEE754_SINGLE = 'SRE'
        cDATA_FORMAT_IEEE754_DOUBLE = 'DRE'
        cDATA_FORMAT_ASCII = 'ASC'
        
        
        % See this.cDataFormatElements
        cDATA_FORMAT_ELEMENTS_READ = 'READ'
        cDATA_FORMAT_ELEMENTS_READ_UNIT = 'READ,UNIT'
        
        
        cCONNECTION_RS232 = 'rs232'
        cCONNECTION_GPIB = 'gpib';
        
    end
        
    properties % (Access = private)
     
        % {serial 1x1}
        s
        dPLCMax = 10;
        dPLCMin = 0.01;
        u8GpibAddress = 28;
        cPort = 'COM1';
        cTerminator = 'CR/LF'; % Default for Instrument does not support any other
        
        % {double 1x1} - timeout of MATLAB {serial}.  Amount of time it
        % will wait for a response before aborting
        dTimeout = 2
        
        % MUST match the setting on the hardware
        % Menu -> Communication -> RS-232 -> Baud 
        u16BaudRate = uint16(9600); % 19200 not working 3/2/2017
        
        
        % IMPORTANT
        % Must configure instrument correctly:
        % Menu -> Communication -> RS232 -> Elements
        % Everything should be off except RDG
        % **** RDG=y (reading) ****
        % RDG#=n (reading# since instrument turned on)
        % UNIT=n (unit)
        % CH#=n (channel)
        % HUM=n (humidity)
        % ETEMP=n (temp)
        % TIME=n (timestamp)
        % STATUS=n
        % VSRC=n (voltage source)
        
        % Store then number of serial commands issued
        dCommandNum = 0;
        cConnection
        
        % {char 1xm} GPIB data format. Must be set to one of the this.cDATA_FORMAT_*
        % constants.  Serial communication only works with ASCII 
        % data format
        cDataFormatGpib
        
        % {char 1xm} Used for setting which elements are returned from a
        % getData() query.  Must be set to one of the this.cDATA_FORMAT_ELEMENTS_*
        % constants. Only going to code support for 'READ' (single
        % property in getData()) but will structure code so that if more
        % elements/properties are desired in a single read, can add a new
        % constant here and add it to a switch block in the dataRead() and
        % unpack the data appropriately
        cDataFormatElements 
        
        cGpibVendor = 'ni';
    end
    methods 
        
        function this = Keithley6517a(varargin)
            
            % Default connection
            this.cConnection = this.cCONNECTION_RS232;
            
            % Default data elements
            this.cDataFormatElements = this.cDATA_FORMAT_ELEMENTS_READ;
            
            % Default GPIB data format
            this.cDataFormatGpib = this.cDATA_FORMAT_ASCII; % IEEE754_SINGLE;
            % this.cDataFormatGpib = this.cDATA_FORMAT_IEEE754_SINGLE;
            
            % Override properties with varargin
            for k = 1 : 2: length(varargin)
                % this.msg(sprintf('passed in %s', varargin{k}));
                if this.hasProp( varargin{k})
                    this.msg(sprintf('settting %s', varargin{k}));
                    this.(varargin{k}) = varargin{k + 1};
                end
            end
        end
        
        function init(this)
            
            this.msg('init');
            switch this.cConnection
                case this.cCONNECTION_RS232
                    % Serial
                    this.msg('init (RS-232 / serial)');
                    try
                        this.s = serial(this.cPort);
                    catch me
                        cMsg = sprintf(...
                            [ ...
                                'The MATLAB serial object could not be instantiated. Not to worry.  Try this: \n', ...
                                '1. Make sure the instrument is configured to communicate over RS232. \n', ...
                                'MENU -> COMMUNICATION -> RS-232 \n', ...
                                '2. Check the serial cable to the hardware. \n', ...
                            ] ...
                        );
                        this.msg(cMsg);
                        rethrow(me);
                    end
                    
                    this.s.Terminator = this.cTerminator; 
                    this.s.BaudRate = this.u16BaudRate;
                    this.s.Timeout = this.dTimeout;
                    this.connect();
                case this.cCONNECTION_GPIB                
                    % GPIB
                    this.msg('init (GPIB)');
                    try
                        this.s = gpib(this.cGpibVendor, 0, this.u8GpibAddress);
                    catch me
                        cMsg = sprintf(...
                            [ ...
                                'The MATLAB gpib object could not be instantiated. Not to worry.  Try this: \n', ...
                                '1. Make sure the instrument is configured to communicate over GPIB. \n', ...
                                'MENU -> COMMUNICATION -> GPIB \n', ...
                                '2. Make sure the GPIB addrees matches this.u8GpibAddress (%s) \n', ...
                                'MENU -> COMMUNICATION -> GPIB -> ADDRESSABLE -> ADDRESS \n', ...
                                 '(This property is settable using varargin syntax on instantiation \n', ...
                                '3. Check the GPIB cable to the hardware. \n', ...
                            ], ...
                            this.u8GpibAddress ...
                        );
                        this.msg(cMsg);
                        rethrow(me);
                    end
                    this.connect();
                    this.setDataFormatGpib(this.cDataFormatGpib);
                    
                    % this.s.EOSCharCode = this.cTerminator;
            end
            this.setDataFormatElements(this.cDataFormatElements);
            
        end
        
        function setDataFormatElements(this, cElements)
            cCmd = sprintf(':form:elem %s', cElements);
            this.writeToSerial(cCmd)
        end
        
        function c = getDataFormatElements(this)
            cCmd = ':form:elem?';
            this.writeToSerial(cCmd);
            c = fscanf(this.s);
        end
        
        % @param {char 1xm} - data format. Use this.cDataFormat* constants
        % RS232 only supports ASCII. If any other format that ASCII is
        % provided, the command has no effect. 
        
        function setDataFormatGpib(this, cFormat)
            cCmd = sprintf(':form %s', cFormat);
            this.writeToSerial(cCmd);
        end
            
        function c = getDataFormat(this)
            cCmd = ':form?';
            this.writeToSerial(cCmd);
            c = fscanf(this.s);
        end
        
        function connect(this)
            if ~strcmp(this.s.Status, 'open')
                try
                    fopen(this.s); 
                catch ME
                    this.msg('connect ERROR');
                    rethrow(ME)
                end
            end
            this.clearBytesAvailable();
        end
        
        
        function disconnect(this)
            this.msg('disconnect()');
            this.clearBytesAvailable();
            if strcmp(this.s.Status, 'open')
                try
                    fclose(this.s);
                catch ME
                    this.msg('disconnect ERROR');
                    rethrow(ME)
                end
            end
            
        end
        
        function c = identity(this)
            cCommand = '*IDN?';
            %tic
            this.writeToSerial(cCommand);
            %toc
            %tic
            c = fscanf(this.s);
            %toc
        end
        
        function clearBytesAvailable(this)
            
            % This doesn't alway work.  I've found that if I overfill the
            % input buffer, call this method, then do a subsequent read,
            % the results come back all with -1.6050e9.  Need to figure
            % this out
            
            % this.msg('clearBytesAvailable()');
            
            while this.s.BytesAvailable > 0
                cMsg = sprintf(...
                    'clearBytesAvailable() clearing %1.0f bytes', ...
                    this.s.BytesAvailable ...
                );
                this.msg(cMsg);
                fread(this.s, this.s.BytesAvailable);
            end
        end
        
        function setFunctionToAmps(this)
            cCommand = ':func "curr"';
            this.writeToSerial(cCommand);
        end
        
        % Set the speed (integration time) of the ADC.  
        % @param {double 1x1} dPLC - the integration time as the number of power 
        %   line cycles.  Min = 0.01 Max = 10.  1 PLC = 1/60s = 16.67 ms @
        %   60Hz or 1/50s = 20 ms @ 50 Hz.
        function setIntegrationPeriodPLC(this, dPLC)
            % [:SENSe[1]]:curr[:DC]:nplc <n>
            
            if (dPLC > this.dPLCMax)
                cMsg = sprintf(...
                    'ERROR: supplied PLC = %1.2f > max allowed = %1.2f', ...
                    dPLC, ...
                    this.dPLCMax ...
                );
                this.log(cMsg);
                return;
            end
            
            if (dPLC < this.dPLCMin)
                cMsg = sprintf(...
                    'ERROR: supplied PLC = %1.2f <  min allowed = %1.2f', ...
                    dPLC, ...
                    this.dPLCMin ...
                );
                this.log(cMsg);
                return;
            end
                
            cCommand = sprintf(':curr:nplc %1.3f', dPLC);
            this.writeToSerial(cCommand);
            
        end
        
        function setIntegrationPeriod(this, dPeriod)
            % [:SENSe[1]]:curr[:DC]:aper <n>
            % <n> =166.6666666667e-6 to 200e-3 Integration period in seconds
            cCommand = sprintf(':curr:aper %1.5e', dPeriod);
             this.writeToSerial(cCommand);
        end
        
        function d = getIntegrationPeriod(this)
            cCommand = ':curr:aper?'; 
            %tic
            this.writeToSerial(cCommand);
            %toc
            %tic
            c = fscanf(this.s);
            %toc
            d = str2double(c);
        end
        
        % For testing command vs. read with dead time in the middle
        % to isolate delays while the instrument fills its buffer with
        % the answer
        
%         function getIntegrationPeriodA(this)
%             cCommand = ':curr:aper?'; 
%             tic
%             this.writeToSerial(cCommand);
%             toc 
%         end
%         
%         function d = getIntegrationPeriodB(this)
%             tic
%             c = fscanf(this.s);
%             toc
%             d = str2double(c);
%         end
        
        
        
        function d = getIntegrationPeriodPLC(this)
            cCommand = ':curr:nplc?';
            this.writeToSerial(cCommand);
            d = str2double(fscanf(this.s));
        end
        
        
        
        % Enable or disable the digital averaging filter 
        % @param {char 1xm} cVal - the state: "ON" of "OFF"
        function setAverageState(this,  cVal) 
            % [:SENSe[1]]:curr[:DC]:aver[:STATe] <b>
            % ON
            % OFF
            cCommand = sprintf(':curr:aver %s', cVal);
             this.writeToSerial(cCommand);
        end
        
        function c = getAverageState(this)
            cCommand = ':curr:aver?';
            this.writeToSerial(cCommand);
            c = fscanf(this.s);
            c = this.stateText(c);
        end
        
        % Set the averaging filter state of a channel
        % @param {char 1xm} cVal - the state: "NONE", "SCAL", "ADV".  I
        % only envision ever using "SCALar" mode.
        function setAverageType(this,  cVal)
            % [:SENSe[1]]:curr[:DC]:aver:TYPE <name>
            % NONE
            % SCALar
            % ADVanced
            cCommand = sprintf(':curr:aver:type %s', cVal);
             this.writeToSerial(cCommand);
        end
        
        function c = getAverageType(this)
            cCommand = ':curr:aver:type?';
            this.writeToSerial(cCommand);
            c = fscanf(this.s);
        end
        
         % Set the averaging filter mode of a channel
        % @param {char 1xm} cVal - the mode: "REPEAT" or "MOVING"
        function setAverageMode(this,  cVal)
            % [:SENSe[1]]:curr[:DC]:aver:tcon <name>
            % REPeat
            % MOVing
            cCommand = sprintf(':curr:aver:tcon %s', cVal);
             this.writeToSerial(cCommand);
        end
        
        function c = getAverageMode(this)
            cCommand = ':curr:aver:tcon?';
            this.writeToSerial(cCommand);
            c = fscanf(this.s);
        end
        
        % Set the averaging filter count of a channel
        % @param {uint8) u8Val - the count (1 to 100)
        function setAverageCount(this, u8Val) 
            % [:SENSe[1]]:curr[:DC]:aver:coun <n>
            cCommand = sprintf(':curr:aver:coun %u', u8Val);
            this.writeToSerial(cCommand);
        end
        
        function u8 = getAverageCount(this)
            this.writeToSerial(':curr:aver:coun?');
            % do not cast as uint8 becasue it screws with HIO
            u8 = str2double(fscanf(this.s));
        end
        
        

        
        
        % Set the median filter state of a channel
        % @param {char 1xm} cVal - the state: "ON" of "OFF"
        function setMedianState(this, cVal)
            % [:SENSe[1]]:curr[:DC]:med[:STATe] <b>
            cCommand = sprintf(':curr:med %s', cVal);
            this.writeToSerial(cCommand);
        end
        
        
        function c = getMedianState(this)
            cCommand = ':curr:med?';
            this.writeToSerial(cCommand);
            c = fscanf(this.s);
            c = this.stateText(c);
        end
        
                
        % Set the median filter rank of a channel
        % @param {uint8) cVal - the rank: 0 (disabled), 1, 2, 3, 4, 5. [3, 5,
        % 7, 9, 11 samples, respectively]
        function setMedianRank(this,  u8Val)
            cCommand = sprintf(':curr:med:rank %u', u8Val);
            this.writeToSerial(cCommand);
            % [:SENSe[1]]:curr[:DC]:med:RANK <NRf>
        end
        
        function u8 = getMedianRank(this)
            cCommand = ':curr:med:rank?';
            this.writeToSerial(cCommand);
            % do not cast as uint8 because it screws with HIO
            u8 = str2double(fscanf(this.s));
        end
                
            
        % Set the range
        % @param {double 1x1} dAmps - the expected current.
        % The Model 6517A will then go to the most sensitive range that
        % will accommodate that expected reading.
        function setRange(this, dAmps)
           % [:SENSe[1]]:curr[:DC]:rang[:UPPer] <n> 
           cCommand = sprintf(':curr:rang %1.3e', dAmps);
           this.writeToSerial(cCommand);
        end
            
        function d = getRange(this)
            cCommand = ':curr:rang?';
            this.writeToSerial(cCommand);
            d = str2double(fscanf(this.s));
        end
        
        % Set the auto range state of a channel
        % @param {char 1xm} cVal - the state: "ON" of "OFF" 
        function setAutoRangeState(this, cVal)
            cCommand = sprintf(':curr:rang:auto %s', cVal);
            this.writeToSerial(cCommand);
        end
        
        function c = getAutoRangeState(this)
            cCommand = ':curr:rang:auto?';
            this.writeToSerial(cCommand);
            c = fscanf(this.s);
            c = this.stateText(c);
        end
        
       
            
        
        % Set the auto range lower limit of a channel
        % @param {double 1x1} dVal - the range: 2e-9, 20e-9, 200e-9, etc.
        function setAutoRangeLowerLimit(this, dVal)
        end
        
        
        % Set the auto range upper limit of a channel
        % @param {double 1x1} dVal - the range: 2e-9, 20e-9, 200e-9, etc.
        function setAutoRangeUpperLimit(this, dVal)  
        end
       
        
        function d = getDataLatest(this) 
           this.clearBytesAvailable();
           cCommand = ':data:lat?';
           this.writeToSerial(cCommand);
           c = fscanf(this.s);
           d = this.dataToDouble(c);
        end
        
        function d = getDataFresh(this)
           cCommand = ':data:fres?';
           this.writeToSerial(cCommand);
           c = fscanf(this.s);
           d = this.dataToDouble(c);
        end
        
        % @param {char 1xm} return of a :data? command.  Will be in
        % different formats depending on this.cConnection and
        % this.cDataFormatGpib
        
        function d = dataToDouble(this, c)
            
            switch this.cConnection
               case this.cCONNECTION_RS232
                   % Always uses ASCII
                    d = str2double(c);
               case this.cCONNECTION_GPIB
                   % Can use ASCII or IEEE754 (Single or Double)
                   switch this.cDataFormatGpib
                       case this.cDATA_FORMAT_ASCII
                           d = str2double(c);
                       case this.cDATA_FORMAT_IEEE754_SINGLE
                           % Requires github/cnanders/matlab-ieee
                           d = c
                       case this.cDATA_FORMAT_IEEE754_DOUBLE
                           d = c
                   end
           end
            
        end
        
        function delete(this)
            this.msg('delete()');
            this.disconnect();
            delete(this.s);
        end
        
        function writeToSerial(this, c)
            cMsg = sprintf('writeToSerial %1.0f: %s', this.dCommandNum, c);
            this.msg(cMsg)
            fprintf(this.s, c)
            this.dCommandNum = this.dCommandNum + 1;
        end
        
        
    end
    
    methods (Access = private)
        
        % The SPCI state? commands return a {char 1xm} representation of 1
        % or 0 followed by the terminator.  The 6517A terminator is CR/LF,
        % which is equivalent to \r\n in matlab. This method converts the
        % {char 1xm} response, for example '1\r\n' or '0\r\n' (except the char
        % doesn't actually equal this, you have to wrap sprintf around it
        % for \r\n to convert.) to 'on' or 'off', respectively
        % @param {char 1xm} - response from SPCI
        % @return {char 1xm} - 'on' or 'off'
           
        function c = stateText(this, cIn)
            
            switch this.cTerminator
                case 'CR'
                    if strcmp(cIn, sprintf('1\r'))
                        c = 'on';
                    else
                        c = 'off';
                    end
                case 'CR/LF'
                    if strcmp(cIn, sprintf('1\r\n'))
                        c = 'on';
                    else
                        c = 'off';
                    end
            end
                    
        end
        
        function msg(this, cMsg)
           fprintf('keithley.keithley6517a.Keithley6517a %s\n', cMsg); 
        end
        function l = hasProp(this, c)
            l = false;
            if length(findprop(this, c)) > 0
                l = true;
            end
            
        end
        
        % @param {char 1xm} c - SPCI serial command
        
    end
    
end
        
