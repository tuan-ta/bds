classdef RecordManager < handle
% RecordManager saves simulation results to be analyzed later

    properties (SetAccess = private)
        Record = [];
    end
    
    methods        
        function record(RM,user)
            rec.TargetUsage = user.TargetUsage;
            rec.NumHelpees = user.NumHelpees;
            rec.NumHelpers = user.NumHelpers;
            rec.NumDataBursts = user.NumDataBursts;
            if strcmpi(user.Status,'death')
                rec.ValuedUsage = user.DeathInstant - ...
                                      user.StartInstant;
                rec.Outage = true;
            else
                rec.ValuedUsage = user.TargetUsage;
                rec.Outage = false;
            end            
            RM.Record = [RM.Record rec];
        end        
    end
end