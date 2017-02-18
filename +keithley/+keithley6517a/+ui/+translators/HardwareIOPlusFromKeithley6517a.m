classdef HardwareIOPlusFromKeithley6517a < InterfaceApiHardwareIOPlus

    properties (Access = private)
        % {< keithley.keithley6517a.AbstractKeithley6517a 1x1}
        device
        cProp
    end
    
    methods

        function this = HardwareIOPlusFromKeithley6517a(device, cProp) 
            this.device = device;
            this.cProp = cProp;
        end
        
        function d = get(this) % retrieve value
            switch this.cProp
                case 'adc-period'
                    d = this.device.getIntegrationPeriod();
                case 'avg-filt-size'
                     d = this.device.getAverageCount();
                case 'med-filt-rank'
                    d = this.device.getMedianRank();
                case 'range'
                    d = this.device.getRange();
            end
            
                    
        end
        
        
        function l = isReady(this) % true when stopped or at its target
            l = true;
        end
        
        function set(this, dDest) % set new destination and move to it
            switch this.cProp
                case 'adc-period'
                    this.device.setIntegrationPeriod(dDest);
                case 'avg-filt-size'
                     this.device.setAverageCount(uint8(dDest));
                case 'med-filt-rank'
                     this.device.setMedianRank(uint8(dDest));
                case 'range'
                     this.device.setRange(dDest);
            end
        end
        
        function stop(this) % stop motion to destination
        end
        
        
        function index(this) % index
        end
        
        function initialize(this)
        end
        
        function l = isInitialized(this)
            l = true;
        end
        
   end
    
    
end
