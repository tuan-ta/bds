classdef SimulationConstants
% Constants used in simulation

    properties (Constant)
        NumUEs = 300;
        SimTime_h = 6;
        SimTimeTick_ms = 1e2; % (ms)
        CooperationFlag = true; % enable/disable cooperation
        LoggingFlag = false; % log events in user's log field
        DebuggingFlag = false;
        
        % Usage model
        MinTargetUsage_h = 0.6;
        MaxTargetUsage_h = 3;
        
        % Traffic model
        InterBurstArrival_s = 30; % (s)
        MeanBurstSize_bytes = 7800; % (bytes)
        
        % Mobility model
        SpeedInterval_mps = [0.1 6]; % (m/s)
        PauseInterval_s = [0 300]; % (s)
        WalkInterval_s = [30 300]; % (s)
        MobilityTolerance_s = 1; % (s) only update position if at least
                                 % this amount of time has passed from the
                                 % last update
        
        % Channel model and battery consumption parameters
        PathlossCompensationFactor = 0.8;
        NumRBsPerSubframe = 2;        
        % Constant energy consumed everytime transmit circuitry is used.
        % This is proportional to the amount of time UE stays in
        % RRC_CONNECTED state. Nominal values (Nokia contribution
        % R2-120367) for pedestrian UEs (3kmph):
        %   - Release Timer: 5 s
        %   - DRX: 160 ms
        %   - InterBurstArrival: 30 s (should be the same as above)
        CircuitryEnergy_mJ = 15; % 3mW * 5s = 15mJ
        
        BatteryCapacity_mJ = 3e4; % (mJ)
        BasePowerU2E_dBm = -69; % -126 to 24 dBm (LTE book pg. 413)
            % An UE in the middle of the cell (250m) spends 3x power per RB
            % compared to idle (1*3 = 3mW)
        BasePowerD2D_dBm = -69;                    
        MaxPower_dBm = 24; % max UL transmit power per RB
        
        % WINNER II channel model parameters
        CarrierFrequency_Hz = 2e9; % (Hz)
        % Urban macro-cell
        BSAntennaHeight_m = 25; % (m)
        UEAntennaHeight_m = 1.5; % (m)
        % Indoor
        NumWallsIndoorNLOS = 1;
        
        % Helper selection algorithm
        UtilityType = 'valued_usage';
        HighThreshold = 0.95;
        LowThreshold = 0.5;
        HelpRange_m = 30; % (m)
        PathlossThreshold_dBm = 110; 
            % UE only requests for help if its path loss is greater than
            % this threshold
    end
    
    methods (Static)
        function SC = toStruct()
            propertyList = properties(SimulationConstants);
            for ip = 1:length(propertyList)
                SC.(propertyList{ip}) = SimulationConstants.(propertyList{ip});
            end
        end
    end
    
end