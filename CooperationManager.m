classdef CooperationManager < handle
% CooperationManager resides at eNodeB and implements helper selection
% algorithm. The same CooperationManager is used for all UEs in the cell.

% Current version: Only one helpee is assigned helper at a time. When there
% are multiple users requesting help at the same clock tick, they are
% served in the order of the requests (almost always the same as the order
% of the user ID - this depends on the loop in main.m). As a result, later
% helpees will have to wait for some number of clock ticks before getting
% helped.

    properties (SetAccess = private)
        Users                
        HelperList = false(1,SimulationConstants.NumUEs);
        NumHelpedSessions = zeros(1,SimulationConstants.NumUEs);
    end

    methods
        function assignUsers(CM,users)
            if length(users)~=SimulationConstants.NumUEs
                error('Number of UEs does not conform with SimulationConstants');
            end
            CM.Users = users;
        end
        
        function updateHelperStatus(CM,uID)
            if strcmpi(CM.Users(uID).StatusCoop,'high')
                CM.HelperList(uID) = true;
            else
                CM.HelperList(uID) = false;
            end
        end
        
        function helper = assignHelper(CM,helpeeID)
        % assignHelper selects among users within range
        
            assignmentMode = 'closest'; % 'closest' or 'max_battery'
            helper = [];
            helpeePos = CM.Users(helpeeID).Position;
            maxBatteryLevel = -Inf; minDistance = Inf;
            for ih = find(CM.HelperList)
                user = CM.Users(ih);
                MobilityManager.updatePosition(user);
                if norm(user.Position-helpeePos) > SimulationConstants.HelpRange_m
                    continue
                end
                
                % #TT design decision: update helper StatusCoop or not
                %   1. Yes: More computation, less cooperation, can use
                %   utility as a metric to choose helper
                %   2. No: Helper might have moved and the new path loss
                %   changes the StatusCoop from 'high' to something else
                % Current choice: Yes
                user.updatePathloss();
                user.updateCoopStatus();
                if ~strcmpi(user.StatusCoop,'high')
                    CM.HelperList(ih) = false;
                    continue
                end
                
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
                CM.NumHelpedSessions(helpeeID) = CM.NumHelpedSessions(helpeeID) + 1;
            end
            if SimulationConstants.DebuggingFlag
                fprintf('Helpee: \n');
                CM.Users(helpeeID)
                helper
            end            
        end
    end
end