classdef CooperationManager < handle
% CooperationManager resides at eNodeB and implements helper selection
% algorithm. The same CooperationManager is used for all UEs in the cell.

    properties (SetAccess = private)
        HelpFlag = false;
        HelpeeID = [];
        HelpeePos = [];
        HelperList = [];
        HelpLog = [];
    end

    methods
        function requestHelp(CM,user)
            if CM.HelpFlag
                error('Another user has already requested help.');
            end
            if ~strcmpi(user.Status,'low')
                error('Helpee must be in ''low'' state.');
            end
            CM.HelpFlag = true;
            CM.HelpeeID = user.ID;
            CM.HelpeePos = user.Position;
            CM.HelpLog = [CM.HelpLog [user.Clock; user.ID; -1]];
        end
        
        function registerHelper(CM,user)
            CM.HelperList = [CM.HelperList user];
        end        
        
        function helper = assignHelper(CM,helpee)
        % assignHelper selects among users within range the one with
        % highest remaning battery level
        
            DEBUG = false;
            assignmentMode = 'closest'; % 'closest' or 'max_battery'
            helper = [];
            maxBatteryLevel = -Inf; minDistance = Inf;
            for ih = 1:length(CM.HelperList)
                user = CM.HelperList(ih);
%                 if norm(user.Position-helpee.Position) > SimulationConstants.HelpRange_m
%                     continue
%                 end
                switch lower(assignmentMode)
                    case 'closest'
                        if norm(user.Position-helpee.Position) < minDistance
                            helper = user;
                            minDistance = norm(user.Position-helpee.Position);
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
                CM.HelpLog(3,end) = helper.ID;
            end
            if DEBUG
                CM
                helper
            end
            clearCooperationManager(CM);      
        end
    end
end

function clearCooperationManager(CM)
    CM.HelpFlag = false;
    CM.HelperList = [];
    CM.HelpeeID = [];
    CM.HelpeePos = [];
end