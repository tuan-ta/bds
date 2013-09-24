classdef LTEMobilityModel
% Class for mobility model
%   Implements Random Duration Model where the speed, pause time and walk
%   time between consecutive points are uniform random

    properties
        SpeedInterval 
        PauseInterval
        WalkInterval
    end
    
    methods
        function mm = LTEMobilityModel(sInv,pInv,wInv)
            if ~(isequal(size(sInv),[1 2]) && ...
                 isequal(size(pInv),[1 2]) && ...
                 isequal(size(wInv),[1 2]))
                error('Intervals have to be 1x2 vectors');
            end
            mm.SpeedInterval = sInv; % (m/s)
            mm.PauseInterval = pInv; % (s)
            mm.WalkInterval = wInv;  % (s)
        end
    end    
end