classdef TrafficManager
% TrafficManager class provides methods that implement a listener for the
% event BurstArrives of LTEUser object. At event trigger,
% TrafficManager generates the next burst arrival instant and size.
% TrafficManager also deducts the amount of energy consumed by the current
% burst from the UE's battery level.

    methods (Static)
        function generateTraffic(user)
            DEBUG = false;
            % calculate path loss
            if ~(strcmpi(user.StatusNoncoop,'death')&&strcmpi(user.StatusCoop,'death')) && ...
                    ~user.WaitingForHelpAssignmentFlag
                user.updatePathloss();
            end
            
            % consume battery for current burst
            %% noncoop
            if ~strcmpi(user.StatusNoncoop,'death') && ~user.WaitingForHelpAssignmentFlag
                consumeEnergy(user,'U2E','Noncoop');
                user.updateNoncoopStatus();
            end
            
            %% coop
            % WaitingForHelpAssignmentFlag should be cleared every time a burst is served
            if ~strcmpi(user.StatusCoop,'death')
                if user.WaitingForHelpAssignmentFlag || ...
                        (SimulationConstants.CooperationFlag && strcmpi(user.StatusCoop,'low') && ...
                        user.PathlossU2E > SimulationConstants.PathlossThreshold_dBm)
                    if ~user.CoopManager.HelpFlag % first to request help                
                        user.CoopManager.requestHelp(user);
                        % check for helper assignment in the next clock
                        user.NextBurstInstant = user.NextBurstInstant + 1;
                        user.WaitingForHelpAssignmentFlag = true;
                        return
                    elseif user.CoopManager.HelpeeID == user.ID % help granted to this UE
                        helper = user.CoopManager.assignHelper(user);
                        if ~isempty(helper)
                            consumeEnergy([user helper],'D2D','Coop');
%{                            
                            if SimulationConstants.LoggingFlag
                                user.Log = [user.Log struct('Time',user.Clock,...
                                                            'Event','Coop',...
                                                            'Details',struct('Helpee',user.ID,...
                                                                             'Helper',helper.ID,...
                                                                             'HelpeePos',user.Position,...
                                                                             'HelperPos',helper.Position,...
                                                                             'HelpeeEnergyConsumed',energy(1),...
                                                                             'HelperEnergyConsumed',energy(2)))];
                            end
%}                            
                        else
                            consumeEnergy(user,'U2E','Coop');
                        end
                        user.WaitingForHelpAssignmentFlag = false;
                        if DEBUG
                            user
                            helper
                        end
                    else % somebody else has already requested help 
                         % wait until next round
                        user.NextBurstInstant = user.NextBurstInstant + 1;
                        user.WaitingForHelpAssignmentFlag = true;
                        return
                    end                   
                else
                    consumeEnergy(user,'U2E','Coop');
                    user.WaitingForHelpAssignmentFlag = false;
                end
                
                user.updateCoopStatus();
            end
            
            if SimulationConstants.LoggingFlag
                logEntry = [1; user.Clock; user.NextBurstSize; user.BatteryLevelNoncoop; user.BatteryLevelCoop; 0];
                if exist('helper','var') && ~isempty(helper)
                    logEntry(6) = helper.ID;
                    logEntryHelper = [0; helper.Clock; user.NextBurstSize; helper.BatteryLevelNoncoop; helper.BatteryLevelCoop; user.ID];
                    helper.Log = [helper.Log logEntryHelper];
                end
                user.Log = [user.Log logEntry];
            end     
            
            %% schedule the next burst
            if strcmpi(user.TrafficModel.InterArrivalType,'geometric')
                if length(user.TrafficModel.InterArrivalParam)==2
                % parameter of the geometric distribution is drawn from
                % a uniform distribution
                    interArrivalParam = random('unif',user.TrafficModel.InterArrivalParam(1),...
                        user.TrafficModel.InterArrivalParam(2));
                else
                    interArrivalParam = user.TrafficModel.InterArrivalParam;
                end
                interArrivalParam = interArrivalParam*1000/SimulationConstants.SimTimeTick_ms;
                nextBurstInstant = random('geo',1/interArrivalParam);
                user.NextBurstInstant = user.NextBurstInstant + max(nextBurstInstant,1);
                if strcmpi(user.TrafficModel.DataSizeType,'geometric')
                    nextBurstSize = random('geo',1/user.TrafficModel.DataSizeParam);
                    user.NextBurstSize = nextBurstSize;
                end
                
%                 if SimulationConstants.LoggingFlag
%                     logData(user);
%                 end                  
                
                if DEBUG
                    fprintf('Data for user %g, next arrival %g, size %g\n',...
                        user.ID,user.NextBurstInstant,user.NextBurstSize);
                end
            end
        end
        
        function addUser(user)
            addlistener(user,'BurstArrives',...
                @(src,evnt)TrafficManager.generateTraffic(src));
        end
    end
end

function energy = consumeEnergy(users,linkType,coopType)
% deduct battery according to burst size, link type and channel at users' 
% location

    DEBUG = false;
    if strcmpi(linkType,'d2d') && strcmpi(coopType,'noncoop')
        error('D2D links are only used in cooperative mode');
    end   
    
    numRBs = ceil(users(1).NextBurstSize*8/100); 
    % 12 (subcarriers) * 7 (symbols/slot) * 4 (bits/symbol) * 0.9 (10% used
    % for control) * 1/3 (code rate) = 100 bits/RB
    if numRBs == 0
        energy = 0;
        return
    end    
    numSubframes = ceil(numRBs/SimulationConstants.NumRBsPerSubframe);
    alpha = SimulationConstants.PathlossCompensationFactor;
    P0 = SimulationConstants.BasePowerU2E_dBm;
    Pmax = SimulationConstants.MaxPower_dBm + 10*log10(SimulationConstants.NumRBsPerSubframe);
    
    if DEBUG
        fprintf('User %g, numRBs = %g\n',users(1).ID,numRBs);
    end
    
    switch lower(linkType)
        case 'u2e'
            if length(users)~=1
                error('U2E link type should only have 1 UE.');
            end
            transmitPower_dBm = min(Pmax, P0 + 10*log10(SimulationConstants.NumRBsPerSubframe) + ...
                alpha*users.PathlossU2E);
            
            energyConsumed_mJ = 10^(transmitPower_dBm/10)*numSubframes*1e-3 + ...
                SimulationConstants.CircuitryEnergy_mJ;
            
            users.depleteBattery(energyConsumed_mJ,coopType);
            energy = energyConsumed_mJ;
%{            
            if SimulationConstants.LoggingFlag
                energyData = struct('Time',users(1).Clock,...
                                    'Event',linkType,...
                                    'Details',struct('PathLoss',ChannelManager.pathloss(users,linkType),...
                                                     'TransmitPower',transmitPower_dBm,...
                                                     'EnergyConsumed',energyConsumed),...
                                                     'ID',users.ID);
                users.Log = [users.Log energyData];
            end
            if DEBUG
                fprintf('U2E energy consumed by user %g: %g\n',users.ID,energyConsumed);
            end
%}            
        case 'd2d'
            if length(users)~=2
                error('D2D link type should have 2 UEs.');
            end            
            helpee = users(1);
            helper = users(2);
            P0D2D = SimulationConstants.BasePowerD2D_dBm;
            helpeeTransmitPower_dBm = min(Pmax, P0D2D + 10*log10(SimulationConstants.NumRBsPerSubframe) + ...
                alpha*ChannelManager.pathloss(users,'D2D')); 
            helperTransmitPower_dBm = min(Pmax, P0 + 10*log10(SimulationConstants.NumRBsPerSubframe) + ...
                alpha*helper.PathlossU2E);
            
            helpeeEnergyConsumed_mJ = 10^(helpeeTransmitPower_dBm/10)*numSubframes*1e-3 + ...
                SimulationConstants.CircuitryEnergy_mJ;
            helperEnergyConsumed_mJ = 10^(helperTransmitPower_dBm/10)*numSubframes*1e-3 + ...
                SimulationConstants.CircuitryEnergy_mJ;
            
            helpee.depleteBattery(helpeeEnergyConsumed_mJ,'coop');
            helper.depleteBattery(helperEnergyConsumed_mJ,'coop');
            energy = [helpeeEnergyConsumed_mJ helperEnergyConsumed_mJ];
%{            
            if SimulationConstants.LoggingFlag
                helpeeEnergyData = struct('Time',helpee.Clock,...
                                          'Event','Helpee',...
                                          'Details',struct('PathLoss',ChannelManager.pathloss(users,'D2D'),...
                                                           'TransmitPower',helpeeTransmitPower_dBm,...
                                                           'EnergyConsumed',helpeeEnergyConsumed),...
                                                           'ID',helper.ID);
                helpee.Log = [helpee.Log helpeeEnergyData];
                helperEnergyData = struct('Time',helper.Clock,...
                                          'Event','Helper',...
                                          'Details',struct('PathLoss',ChannelManager.pathloss(helper,'U2E'),...
                                                           'TransmitPower',helperTransmitPower_dBm,...
                                                           'EnergyConsumed',helperEnergyConsumed),...
                                                           'ID',helpee.ID);
                helper.Log = [helper.Log helperEnergyData];
            end
%}            
            if DEBUG
                fprintf('D2D path loss for user %g: %g\n',helpee.ID,ChannelManager.pathloss(users,'D2D'));
                fprintf('U2E path loss for user %g: %g\n',helper.ID,ChannelManager.pathloss(helper,'U2E'));
                fprintf('D2D transmit power for user %g: %g\n',helpee.ID,helpeeTransmitPower_dBm);
                fprintf('U2E transmit power for user %g: %g\n',helper.ID,helperTransmitPower_dBm);
                fprintf('D2D energy consumed by user %g: %g\n',helpee.ID,helpeeEnergyConsumed_mJ);
                fprintf('U2E energy consumed by user %g: %g\n',helper.ID,helperEnergyConsumed_mJ);
            end
        otherwise
            error('linkType should be U2E or D2D.');
    end    
end

function logData(user)
% record traffic data
    
    trafficData = struct('Time',user.Clock,...
                         'Event','Traffic',...
                         'Details',struct('RemainingBatteryCoop',user.BatteryLevelCoop,...
                                          'RemainingBatteryNoncoop',user.BatteryLevelNoncoop,...
                                          'NextBurstArrival',user.NextBurstInstant,...
                                          'NextBurstSize',user.NextBurstSize,...
                                          'Position',user.Position));
    user.Log = [user.Log trafficData];
end