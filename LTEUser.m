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
        RecordManager
        StartInstant
        StopInstant
        TargetUsage
        UtilType
        Utility
        PathlossU2E
    end
    
    properties
        Status
            % inactive: before start instant
            % low: needing help
            % high: can help
            % medium: neither
            % stopped: after stop instant
            % death        
        % traffic-related properties
        NextBurstInstant
        NextBurstSize % (bytes)
        % mobility-related properties
        NextMovementInstant
        Speed % (m/s)
        Direction % (rad)
        WalkTimeMarker % keeping track of last time instant that position was updated
        Log % each log entry is a 6x1 column vector - Matlab is more efficient with vectors than structs
            %   1. Data ownership flag (1: own data, 0: helping somebody else)
            %   2. Time instant (in simulation tick)
            %   3. Burst size (in bytes)
            %   4. Remaining battery (in mJ)            
            %   5. ID of the other UE for D2D if coop happened, 0 otherwise        
        DeathInstant        
        NumDataBursts
        NumHelpers
        NumHelpees
    end
    
    events
        BurstArrives
        NextMovementEvent
    end
    
    methods
        function u = LTEUser(id,cell)
            if nargin > 0 % handle no argument constuctor for users array preallocation
                u.ID = id;
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
                u.UtilType = SimulationConstants.UtilityType;
                u.Cell = cell;
                u.reinitiate();
            end
        end
        
        function reinitiate(u)
%             initBatteryLevel = SimulationConstants.BatteryCapacity_mJ;
            initBatteryLevel = SimulationConstants.BatteryCapacity_mJ*...
                    random('unif',SimulationConstants.MinBatteryLevel,...
                                  SimulationConstants.MaxBatteryLevel);
            u.BatteryLevel = initBatteryLevel;            
            u.StartInstant = u.Clock;
            targetUsage_h = SimulationConstants.MaxTargetUsage_h * ...
                    random('unif',SimulationConstants.MinTargetUsageLevel,...
                                  SimulationConstants.MaxTargetUsageLevel);
            u.TargetUsage = ceil(targetUsage_h*3600e3/SimulationConstants.SimTimeTick_ms);
            u.StopInstant = u.StartInstant + u.TargetUsage;
            u.NextBurstInstant = u.Clock;
            u.NextBurstSize = 0;
            u.NextMovementInstant = u.Clock;
            u.Speed = 0;
            u.Direction = 0;
            u.WalkTimeMarker = u.Clock;
            u.Status = 'inactive';            
            u.DeathInstant = Inf;            
            u.NumDataBursts = 0;
            u.NumHelpers = 0;
            u.NumHelpees = 0;
            u.Position = u.Cell.randomPosition();
        end
        
        function clockTick(u)
            if strcmpi(u.Status,'death')
                error('Death UE shouldn''t tick clock.');
            end
            
            if u.Clock < u.StartInstant
                u.Clock = u.Clock + 1;
                return
            elseif u.Clock == u.StartInstant % bootstrap for traffic manager and mobility manager                                                
                u.NextBurstInstant = u.StartInstant;
                u.NextMovementInstant = u.StartInstant;
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
                u.record();
            end
        end
        
        function assignCell(u,C)
            u.Cell = C;
        end
        
        function assignCoopManager(u,CM)
            u.CoopManager = CM;
        end
        
        function assignRecordManager(u,RM)
            u.RecordManager = RM;
        end
        
        function assignPosition(u,pos)
            u.Position = pos;
        end
        
        function updatePosition(u)
            if (u.Clock - u.WalkTimeMarker) >= ...
                    SimulationConstants.MobilityTolerance_s*1000/SimulationConstants.SimTimeTick_ms
                MobilityManager.updatePosition(u); 
            end
        end
        
        function updatePathloss(u)            
            u.PathlossU2E = ChannelManager.pathloss(u,'U2E');
        end
        
        function depleteBattery(u,bat)
            u.BatteryLevel = u.BatteryLevel - bat;
        end
        
        function assignParticipateInstants(u,start,stop)
            u.StartInstant = ceil(start);
            u.StopInstant = ceil(stop);
        end
        
        function updateStatus(u)
            if u.BatteryLevel <= 0
                u.Status = 'death';
                u.DeathInstant = u.Clock;                
                u.record();
                return
            end
            
            util = computeUtility(u);
            u.Utility = util;
            if util >= SimulationConstants.HighThreshold
                u.Status = 'high';
            elseif util >= SimulationConstants.LowThreshold
                u.Status = 'medium';
            elseif strcmpi(u.UtilType,'prob_survival') && util < 0
                % #TT temporary hardcoded the lowest utility of
                % participating UE
                u.Status = 'not_participating';
            else
                u.Status = 'low';
            end
        end
        
        function record(u)
            u.RecordManager.record(u);
            u.reinitiate();
        end
    end
end

function util = computeUtility(user)
% compute utility value based on user's utility type

    if strcmpi(user.UtilType,'battery')
        util = user.BatteryLevel/SimulationConstants.BatteryCapacity_mJ;
        return
    end

    % compute unit energy consumption based on user's path loss. This is rho_0
    % in the paper
    alpha = SimulationConstants.PathlossCompensationFactor;
    P0 = SimulationConstants.BasePowerU2E_dBm;
    Pmax = SimulationConstants.MaxPower_dBm + 10*log10(SimulationConstants.NumRBsPerSubframe);
    unitPower_dBm = min(Pmax, P0 + 10*log10(SimulationConstants.NumRBsPerSubframe) + ...
                alpha*user.PathlossU2E);
    unitEnergy_mJ = 10^(unitPower_dBm/10)*1e-3;
    
    b = floor(user.BatteryLevel/unitEnergy_mJ);
    t = user.StopInstant - user.Clock;
    if ~strcmpi(user.TrafficModel.InterArrivalType,'geometric')||...
            ~strcmpi(user.TrafficModel.DataSizeType,'geometric')
        error('Traffic model not supported.');
    end    
    lambda = 1/(user.TrafficModel.InterArrivalParam*1000/SimulationConstants.SimTimeTick_ms);
    nu = 1/(user.TrafficModel.DataSizeParam*8/100);
    switch lower(user.UtilType)
        case 'prob_survival'
            util = utility(t,b,lambda,nu);
        case 'valued_usage'
            util = utility2(t,b,lambda,nu);
        otherwise
            error('Utility type not recognized.');
    end
end    