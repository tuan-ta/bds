classdef CooperationManager < handle
% CooperationManager resides at eNodeB and implements helper selection
% algorithm. The same CooperationManager is used for all UEs in the cell.

    properties (SetAccess = private)
        Users                
        HelperList = false(1,SimulationConstants.NumUEs);
        NumHelpedSessions = zeros(1,SimulationConstants.NumUEs);
        LastMobilityUpdateClock = 0;
        NumHelpRequests = 0;
        NumHelpGranted = 0;
    end

    methods
        function assignUsers(CM,users)
            if length(users)~=SimulationConstants.NumUEs
                error('Number of UEs does not conform with SimulationConstants');
            end
            CM.Users = users;
        end
        
        function updateHelperStatus(CM,uID)
            if strcmpi(CM.Users(uID).Status,'high')
                CM.HelperList(uID) = true;
            else
                CM.HelperList(uID) = false;
            end
        end
        
        function helper = assignHelper(CM,helpeeID)
        % assignHelper selects among users within range
        
            CM.NumHelpRequests = CM.NumHelpRequests + 1;
            assignmentMode = 'closest'; % 'closest' or 'max_battery'
            helpee = CM.Users(helpeeID);
            helper = [];
            helpeePos = helpee.Position;
            
            % find potential helpers within range
            helperIndices = find(CM.HelperList);
            helpersPos = zeros(length(helperIndices),2);
            if (helpee.Clock - CM.LastMobilityUpdateClock) > ...
                    SimulationConstants.MobilityTolerance_s*1000/...
                    SimulationConstants.SimTimeTick_ms
                for ihp = 1:length(helperIndices)
                    ih = helperIndices(ihp);
                    CM.Users(ih).updatePosition();
                    helpersPos(ihp,:) = CM.Users(ih).Position;
                end
                CM.LastMobilityUpdateClock = helpee.Clock;
            else % do not update helper position to reduce computation
                for ihp = 1:length(helperIndices)
                    ih = helperIndices(ihp);                    
                    helpersPos(ihp,:) = CM.Users(ih).Position;
                end
            end
            helpersInRange = sum((helpersPos - repmat(helpeePos,length(helperIndices),1)).^2,2) ...
                            <= SimulationConstants.HelpRange_m^2;
            potentialHelperIndices = helperIndices(helpersInRange);
            
            % select helper            
            maxBatteryLevel = -Inf; minDistance = Inf;
            for ih = potentialHelperIndices
                % #TT design decision: update helper StatusCoop or not
                %   1. Yes: More computation, less cooperation, can use
                %   utility as a metric to choose helper
                %   2. No: Helper might have moved and the new path loss
                %   changes the StatusCoop from 'high' to something else
                % Current choice: No
                user = CM.Users(ih);
                user.updatePathloss();
%                 user.updateCoopStatus();
%                 if ~strcmpi(user.StatusCoop,'high')
%                     CM.HelperList(ih) = false;
%                     continue
%                 end
                
                switch lower(assignmentMode)
                    case 'closest'
                        if norm(user.Position-helpeePos) < minDistance
                            helper = user;
                            minDistance = norm(user.Position-helpeePos);
                        end
                    case 'max_battery'
                        if user.BatteryLevel > maxBatteryLevel
                            helper = user;
                            maxBatteryLevel = user.BatteryLevel;
                        end
                    otherwise
                        error(['Helper assignment mode ''' assignmentMode ''' is not supported.']);
                end
            end
            if ~isempty(helper)
                CM.NumHelpGranted = CM.NumHelpGranted + 1;
                CM.NumHelpedSessions(helpeeID) = CM.NumHelpedSessions(helpeeID) + 1;
                helpee.NumHelpees = helpee.NumHelpees + 1;
                helper.NumHelpers = helper.NumHelpers + 1;
            end
            if SimulationConstants.DebuggingFlag
                fprintf('Helpee: \n');
                helpee
                helper
            end            
        end
    end
end