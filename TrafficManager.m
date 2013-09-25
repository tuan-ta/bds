classdef TrafficManager
% TrafficManager class provides methods that implement a listener for the
% event NextBurstArrives of LTEUser object. At event trigger,
% TrafficManager generates the next burst arrival instant and size.
% TrafficManager also deducts the amount of energy consumed by the current
% burst from the UE's battery level.

    methods (Static)
        function generateTraffic(user)
            DEBUG = false;
            
            % consume battery for current burst
            if SimulationConstants.CooperationFlag && strcmpi(user.Status,'low') && ...
                    ChannelManager.pathloss(user,'U2E') > SimulationConstants.PathlossThreshold_dBm
                if ~user.CoopManager.HelpFlag % first to request help                
                    user.CoopManager.requestHelp(user);
                    % check for helper assignment in the next clock
                    user.NextBurstInstant = user.NextBurstInstant + 1;
                    return
                elseif user.CoopManager.HelpeeID == user.ID % help granted to this UE
                    helper = user.CoopManager.assignHelper(user);
                    if ~isempty(helper)
                        consumeEnergy([user helper],'D2D');                        
                    else
                        consumeEnergy(user,'U2E');
                    end
                    if DEBUG
                        user
                        helper
                    end
                else % somebody else has already requested help 
                     % #TODO implement multiple help requests
                    consumeEnergy(user,'U2E');
                end                   
            else
                consumeEnergy(user,'U2E');
            end
            
            % update UE's status
            if user.BatteryLevel >= SimulationConstants.HighThreshold*SimulationConstants.BatteryCapacity_mJ
                user.Status = 'high';
            elseif user.BatteryLevel >= SimulationConstants.LowThreshold*SimulationConstants.BatteryCapacity_mJ
                user.Status = 'medium';
            elseif user.BatteryLevel > 0
                user.Status = 'low';
            else
                user.Status = 'death';
                return
            end
            
            % schedule the next burst
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

function consumeEnergy(users,linkType)
% deduct battery according to burst size, link type and channel at users' 
% location

    DEBUG = false;    
    numRBs = ceil(users(1).NextBurstSize*8/100); 
    % 12 (subcarriers) * 7 (symbols/slot) * 4 (bits/symbol) * 0.9 (10% used
    % for control) * 1/3 (code rate) = 100 bits/RB
    if numRBs == 0
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
                alpha*ChannelManager.pathloss(users,linkType));
            % energy consumed: assume that all sessions last over the same amount
            % of time or assuming that the number of subframes is proportional to
            % the number of RBs?

            energyConsumed = 10^(transmitPower_dBm/10)*numSubframes*1e-3 + ...
                SimulationConstants.CircuitryEnergy_mJ;
            
            users.depleteBattery(energyConsumed);
%             if SimulationConstants.LoggingFlag
%                 energyData = struct('Time',users(1).Clock,...
%                                     'Event',linkType,...
%                                     'Details',struct('PathLoss',ChannelManager.pathloss(users,linkType),...
%                                                      'TransmitPower',transmitPower_dBm,...
%                                                      'EnergyConsumed',energyConsumed),...
%                                                      'ID',users.ID);
%                 users.Log = [users.Log energyData];
%             end
%             if DEBUG
%                 fprintf('U2E energy consumed by user %g: %g\n',users.ID,energyConsumed);
%             end
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
                alpha*ChannelManager.pathloss(helper,'U2E'));
            
            helpeeEnergyConsumed = 10^(helpeeTransmitPower_dBm/10)*numSubframes*1e-3 + ...
                SimulationConstants.CircuitryEnergy_mJ;
            helperEnergyConsumed = 10^(helperTransmitPower_dBm/10)*numSubframes*1e-3 + ...
                SimulationConstants.CircuitryEnergy_mJ;
            
            helpee.depleteBattery(helpeeEnergyConsumed);
            helper.depleteBattery(helperEnergyConsumed);
%             if SimulationConstants.LoggingFlag
%                 helpeeEnergyData = struct('Time',helpee.Clock,...
%                                           'Event','Helpee',...
%                                           'Details',struct('PathLoss',ChannelManager.pathloss(users,'D2D'),...
%                                                            'TransmitPower',helpeeTransmitPower_dBm,...
%                                                            'EnergyConsumed',helpeeEnergyConsumed),...
%                                                            'ID',helper.ID);
%                 helpee.Log = [helpee.Log helpeeEnergyData];
%                 helperEnergyData = struct('Time',helper.Clock,...
%                                           'Event','Helper',...
%                                           'Details',struct('PathLoss',ChannelManager.pathloss(helper,'U2E'),...
%                                                            'TransmitPower',helperTransmitPower_dBm,...
%                                                            'EnergyConsumed',helperEnergyConsumed),...
%                                                            'ID',helpee.ID);
%                 helper.Log = [helper.Log helperEnergyData];
%             end
            if DEBUG
                fprintf('D2D path loss for user %g: %g\n',helpee.ID,ChannelManager.pathloss(users,'D2D'));
                fprintf('U2E path loss for user %g: %g\n',helper.ID,ChannelManager.pathloss(helper,'U2E'));
                fprintf('D2D transmit power for user %g: %g\n',helpee.ID,helpeeTransmitPower_dBm);
                fprintf('U2E transmit power for user %g: %g\n',helper.ID,helperTransmitPower_dBm);
                fprintf('D2D energy consumed by user %g: %g\n',helpee.ID,helpeeEnergyConsumed);
                fprintf('U2E energy consumed by user %g: %g\n',helper.ID,helperEnergyConsumed);
            end
        otherwise
            error('linkType should be U2E or D2D.');
    end    
end

function logData(user)
% record traffic data

    trafficData = struct('Time',user.Clock,...
                         'Event','Traffic',...
                         'Details',struct('RemainingBattery',user.BatteryLevel,...
                                          'NextBurstArrival',user.NextBurstInstant,...
                                          'NextBurstSize',user.NextBurstSize));
    user.Log = [user.Log trafficData];
end