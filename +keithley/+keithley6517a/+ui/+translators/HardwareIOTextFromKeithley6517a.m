classdef HardwareIOTextFromKeithley6517a < InterfaceApiHardwareIOText
    
    properties (Access = private)
        % {< keithley.keithley6517a.AbstractKeithley6517a 1x1}
        device
        cProp
    end
    
    methods
        
        function this = HardwareIOTextFromKeithley6517a(device, cProp) 
            this.device = device;
            this.cProp = cProp;
        end
        
        function c = get(this) % retrieve value
            switch this.cProp
                case 'auto-range-state'
                    c = this.device.getAutoRangeState();
                case 'avg-filt-mode'
                    c = this.device.getAverageMode();
                case 'avg-filt-state'
                    c = this.device.getAverageState();
                case 'avg-filt-type'
                    c = this.device.getAverageType();
                case 'med-filt-state'
                    c = this.device.getMedianState();
            end
        end
            
        function set(this, cVal) % set new value
            switch this.cProp
                case 'auto-range-state'
                    this.device.setAutoRangeState(cVal);
                case 'avg-filt-mode'
                    this.device.setAverageMode(cVal);
                case 'avg-filt-state'
                    this.device.setAverageState(cVal);
                case 'avg-filt-type'
                     this.device.setAverageType(cVal);
                case 'med-filt-state'
                    this.device.setMedianState(cVal);
            end
        end
        
        
    end
    
    
    
end
