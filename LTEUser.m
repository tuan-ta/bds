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
        StartInstant
        StopInstant
    end
    
    properties
        Status = 'inactive'; 
            % inactive: before start instant
            % low: needing help
            % high: can help
            % medium: neither
            % stopped: after stop instant
            % death
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
            if strcmpi(u.Status,'death') || strcmpi(u.Status,'stopped')
                return            
            end
            
            if u.Clock < u.StartInstant
                u.Clock = u.Clock + 1;
                return
            elseif u.Clock == u.StartInstant % bootstrap for traffic manager and mobility manager
                u.Status = 'high';
                u.NextBurstInstant = u.StartInstant;
                u.NextMovementInstant = u.StartInstant;
            end
            
            if u.CoopManager.HelpFlag && strcmpi(u.Status,'high')
                MobilityManager.updatePosition(u);
                if norm(u.Position-u.CoopManager.HelpeePos) <= SimulationConstants.HelpRange_m
                    u.CoopManager.registerHelper(u);
                end
            end
            
            % event triggers happen before clock tick to make scheduling start at time 0
            if u.Clock == u.NextBurstInstant
                notify(u,'BurstArrives');
            end
            if u.Clock == u.NextMovementInstant
                notify(u,'NextMovementEvent');
            end
            u.Clock = u.Clock + 1;
            if u.Clock == u.StopInstant
                u.Status = 'stopped';
            end
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
        
        function assignParticipateInstants(u,start,stop)
            u.StartInstant = ceil(start);
            u.StopInstant = ceil(stop);
        end
    end
end