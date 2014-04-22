%% generate figures for special issue submission
% analyze multiple recordManagers
% assuming appropriate simulation data is obtained and stored in data/
% subfolder
SimTime_h = 2;
MaxTargetUsage_h = 0.5;
MinTargetUsageLevel = 0.2;
MaxTargetUsageLevel = 1;
BatteryCapacity_mJ = 4e3;
MinBatteryLevel = 1;
MaxBatteryLevel = 1;
HighThreshold = 0.9;
LowThreshold = 0.5;
NumUEs = 500;
macroCellRadius = 300;

UtilityTypes = {'prob_survival','valued_usage','battery'};
rm = {};
for iu = 1:length(UtilityTypes)
    UtilityType = UtilityTypes{iu};
    fn = sprintf('data/%gh_%gh_%g_%g_%gmJ_%g_%g_%s_%g_%g_%g_%g_%g.mat',...
             SimTime_h,...
             MaxTargetUsage_h,...
             MinTargetUsageLevel,...
             MaxTargetUsageLevel,...
             BatteryCapacity_mJ,...
             MaxBatteryLevel,...
             MinBatteryLevel,...
             UtilityType,...
             HighThreshold,...
             LowThreshold,...
             NumUEs,...
             macroCellRadius,...
             1);
    load(fn,'recordManager','cooperationManager');
    rm{iu} = recordManager;
    cm{iu} = cooperationManager;
end
fn = sprintf('data/%gh_%gh_%g_%g_%gmJ_%g_%g_%s_%g_%g_%g_%g_%g.mat',...
         SimTime_h,...
         MaxTargetUsage_h,...
         MinTargetUsageLevel,...
         MaxTargetUsageLevel,...
         BatteryCapacity_mJ,...
         MaxBatteryLevel,...
         MinBatteryLevel,...
         'battery',...
         HighThreshold,...
         LowThreshold,...
         NumUEs,...
         macroCellRadius,...
         0);
load(fn,'recordManager','cooperationManager');
rm{4} = recordManager;
cm{4} = cooperationManager;
%
for ir = 1:length(rm)
    rec = rm{ir}.Record;
    len = length(rec);
    valuedUsage{ir} = zeros(1,len);
    valuedUsageNormalized{ir} = zeros(1,len);
    numOutage = 0;
    for iR = 1:len
        r = rec(iR);
        valuedUsage{ir}(iR) = r.ValuedUsage;
        valuedUsageNormalized{ir}(iR) = r.ValuedUsage/r.TargetUsage;
        numOutage = numOutage + r.Outage;
    end
    probOutage(ir) = numOutage/len;
    helpGrantedRatio(ir) = cm{ir}.NumHelpGranted/cm{ir}.NumHelpRequests;
end

% ratio of valued usage gain for the whole network (use mean because of
% different sample sizes)
for ir = 1:length(rm)
    meanValuedUsage(ir) = mean(valuedUsage{ir});
end
for ir = 1:length(rm)-1
    gainRatio(ir) = meanValuedUsage(ir)/meanValuedUsage(end);
end
meanValuedUsage
gainRatio

%
color = {'b','r','k','g'};
linestyle = {'--','-','-.',':'};
figure;
hold all
for ir = 1:length(rm)
    h = cdfplot(valuedUsageNormalized{ir});
    set(h,'color',color{ir},'linestyle',linestyle{ir},'linewidth',2);
end
title('CDF of valued usage time','fontsize',18);
xlabel('T_V/T','fontsize',14);
ylabel('Probability','fontsize',14);
set(gca,'fontsize',14);
ylim([0 0.52]);
legend('Probability of survival','Valued usage','Battery','No cooperation',...
       'location','NorthWest');
% print('-depsc','fig/simulTV2.eps','-r300');
