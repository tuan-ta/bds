classdef LTETrafficModel
% Class for traffic models

    properties
        InterArrivalType
        InterArrivalParam 
        DataSizeType
        DataSizeParam 
    end
    
    methods
        function tm = LTETrafficModel(iaMean,dsMean)
            tm.InterArrivalType = 'geometric';
            tm.InterArrivalParam = iaMean; %(sec)
            tm.DataSizeType = 'geometric';
            tm.DataSizeParam = dsMean; % (bytes)
        end
    end
end