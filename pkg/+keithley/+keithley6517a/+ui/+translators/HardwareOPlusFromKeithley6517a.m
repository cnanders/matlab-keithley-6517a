classdef HardwareOPlusFromKeithley6517a < InterfaceApiHardwareOPlus
    
    properties (Access = private)
        % {< keithley.keithley6517a.AbstractKeithley6517a 1x1}
        device
        cProp
    end
    
    methods
        
        function this = HardwareOPlusFromKeithley6517a(device, cProp) 
            this.device = device;
            this.cProp = cProp;
        end
        
        function d = get(this) % retrieve value
            cMsg = sprintf('get %s', this.cProp);
            % this.msg(cMsg);
            switch this.cProp
                case 'data'
                    d = this.device.getDataLatest();
            end
        end
        
        function l = isInitialized(this)
            % this.msg('isInitialized')
            l = false;
        end
        
    end
    
    
    
end
