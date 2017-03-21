classdef TestUiKeithley6517a < HandlePlus
    
    properties
        clock
        ui
        device
    end
    
    properties (Access = private)
        
        config
        h
        
    end
    
    methods
        
        function this = TestUiKeithley6517a()
        
            this.clock = Clock('master');
            this.ui = keithley.keithley6517a.ui.UiKeithley6517a(...
                'clock', this.clock, ...
                'lShowSettings', false, ...
                'lShowRange', false ...
            );
        
            
            % Set the Api
            this.device = keithley.keithley6517a.Keithley6517a( ...
                'cConnection', keithley.keithley6517a.Keithley6517a.cCONNECTION_GPIB ...
            );
            this.device.init();
            % this.device = keithley.keithley6517a.Keithley6517aVirtual();
            this.ui.setApi(this.device);
            
        end
        
        function build(this)
            
            this.h = figure;
            this.ui.build(this.h, 10, 10);
            
        end
        
        
        function delete(this)
            this.msg('delete', 5);
            delete(this.ui);
            delete(this.clock);
        end
    
    end
    
end



