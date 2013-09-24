classdef LTEUser < handle
% Class representing LTE users

    properties (SetAccess = private)
        ID
        BatteryLevel        
        TrafficModel
        MobilityModel
        Clock
        Position
        Cell
        CoopManager
    end
    
    properties
        Status = 'high'; % low (needing help), high (can help), medium (neither), death
        % traffic-related properties
        NextBurstInstant = 0;
        NextBurstSize = 0; % (bytes)
        % mobility-related properties
        NextMovementInstant = 0;
        Speed = 0; % (m/s)
        Direction = 0; % (rad)
        WalkTimeMarker = 0; % keeping track of last time instant that position was updated
        Log
    end
    
    events
        BurstArrives
        NextMovementEvent
    end
    
    methods
        function u = LTEUser(id)
            u.ID = id;
            u.BatteryLevel = SimulationConstants.BatteryCapacity_mJ;
            u.Clock = 0;
            u.Position = [0 0];
            u.TrafficModel = LTETrafficModel(SimulationConstants.InterBurstArrival_s,...
                                             SimulationConstants.MeanBurstSize_bytes);
            u.MobilityModel = LTEMobilityModel(SimulationConstants.SpeedInterval_mps,...
                                               SimulationConstants.PauseInterval_s,...
                                               SimulationConstants.WalkInterval_s);
            TrafficManager.addUser(u);
            MobilityManager.addUser(u);
        end
        
        function clockTick(u)
            if strcmpi(u.Status,'death')
                return            
            end
            
            if strcmpi(u.Status,'high') && u.CoopManager.HelpFlag &&...
                    norm(u.Position-u.CoopManager.HelpeePos) <= SimulationConstants.HelpRange_m
                u.CoopManager.registerHelper(u);
            end
            
            % event triggers happen before clock tick to make scheduling start at time 0
            if u.Clock == u.NextBurstInstant
                notify(u,'BurstArrives');
            end
            if u.Clock == u.NextMovementInstant
                notify(u,'NextMovementEvent');
            end
            u.Clock = u.Clock + 1;
        end
        
        function assignCell(u,C)
            u.Cell = C;
        end
        
        function assignCoopManager(u,CM)
            u.CoopManager = CM;
        end
        
        function assignPosition(u,pos)
            u.Position = pos;
        end
        
        function depleteBattery(u,bat)
            u.BatteryLevel = u.BatteryLevel - bat;
        end
    end
end