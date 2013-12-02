classdef LTEUser < handle
% Class representing LTE users

    properties (SetAccess = private)
        ID
        BatteryLevelNoncoop
        BatteryLevelCoop
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
        StatusCoop = 'inactive'; 
            % inactive: before start instant
            % low: needing help
            % high: can help
            % medium: neither
            % stopped: after stop instant
            % death
        StatusNoncoop = 'inactive';
            % inactive: before start instant
            % active
            % stopped
            % death
        % traffic-related properties
        NextBurstInstant = 0;
        NextBurstSize = 0; % (bytes)
        % mobility-related properties
        NextMovementInstant = 0;
        Speed = 0; % (m/s)
        Direction = 0; % (rad)
        WalkTimeMarker = 0; % keeping track of last time instant that position was updated
        Log % each log entry is a 6x1 column vector - Matlab is more efficient with vectors than structs
            %   1. Data ownership flag (1: own data, 0: helping somebody else)
            %   2. Time instant (in simulation tick)
            %   3. Burst size (in bytes)
            %   4. Remaining battery for noncoop (in mJ)
            %   5. Remaining battery for coop (in mJ)
            %   6. ID of the other UE for D2D if coop happened, 0 otherwise
        WaitingForHelpAssignmentFlag = false;
        DeathInstantCoop = Inf;
        DeathInstantNoncoop = Inf;        
    end
    
    events
        BurstArrives
        NextMovementEvent
    end
    
    methods
        function u = LTEUser(id)
            u.ID = id;
%             initBatteryLevel = SimulationConstants.BatteryCapacity_mJ;
            initBatteryLevel = SimulationConstants.BatteryCapacity_mJ*...
                random('unif',SimulationConstants.LowThreshold,1);
            u.BatteryLevelCoop = initBatteryLevel;
            u.BatteryLevelNoncoop = initBatteryLevel;
            u.Clock = 0;
            u.Position = [0 0];
            % usage rate varies from "day" to "day"
%             numRates = length(SimulationConstants.InterBurstArrival_s);
%             rate = SimulationConstants.InterBurstArrival_s(ceil(numRates*random('unif',0,1)));
%             u.TrafficModel = LTETrafficModel(rate,...
%                                              SimulationConstants.MeanBurstSize_bytes);            
            u.TrafficModel = LTETrafficModel(SimulationConstants.InterBurstArrival_s,...
                                             SimulationConstants.MeanBurstSize_bytes);
            u.MobilityModel = LTEMobilityModel(SimulationConstants.SpeedInterval_mps,...
                                               SimulationConstants.PauseInterval_s,...
                                               SimulationConstants.WalkInterval_s);
            TrafficManager.addUser(u);
            MobilityManager.addUser(u);
        end
        
        function clockTick(u)
            if (strcmpi(u.StatusCoop,'death') || strcmpi(u.StatusCoop,'stopped')) && ...
                    (strcmpi(u.StatusNoncoop,'death') || strcmpi(u.StatusNoncoop,'stopped'))
                return            
            end
            
            if u.Clock < u.StartInstant
                u.Clock = u.Clock + 1;
                return
            elseif u.Clock == u.StartInstant % bootstrap for traffic manager and mobility manager
                u.StatusCoop = 'high';
                u.StatusNoncoop = 'active';
                u.NextBurstInstant = u.StartInstant;
                u.NextMovementInstant = u.StartInstant;
            end
            
            if u.CoopManager.HelpFlag && strcmpi(u.StatusCoop,'high')
                MobilityManager.updatePosition(u);
                if norm(u.Position-u.CoopManager.HelpeePos) <= SimulationConstants.HelpRange_m
                    u.CoopManager.registerHelper(u);
                    
                    if SimulationConstants.DebugFlag
                        fprintf('Clock: %g, Helpee: %g, potential helper: %g, distance: %g\n',...
                            u.Clock,u.CoopManager.HelpeeID,u.ID,norm(u.Position-u.CoopManager.HelpeePos));
                    end
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
                u.StatusCoop = 'stopped';
                u.StatusNoncoop = 'stopped';
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
        
        function depleteBattery(u,bat,type)
            switch lower(type)
                case 'coop'
                    u.BatteryLevelCoop = u.BatteryLevelCoop - bat;
                case 'noncoop'
                    u.BatteryLevelNoncoop = u.BatteryLevelNoncoop - bat;
                otherwise
                    error('Type has to be either coop or noncoop.');
            end
        end
        
        function assignParticipateInstants(u,start,stop)
            u.StartInstant = ceil(start);
            u.StopInstant = ceil(stop);
        end
    end
end