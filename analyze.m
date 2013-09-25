%%
fn = sprintf('data/noncoop_%gh_%gms_%gB_%gmJ_0101_1.mat',...
    SimulationConstants.SimTime_h,...
    SimulationConstants.SimTimeTick_ms,...
...%     SimulationConstants.InterBurstArrival_s,...
    SimulationConstants.MeanBurstSize_bytes,...
    SimulationConstants.BatteryCapacity_mJ);
save(fn);

%%
deathClock = zeros(1,length(users));
for iu = 1:length(users)
    deathClock(iu) = users(iu).Clock;
end
figure;cdfplot(deathClock)
title('Final clock of all UEs');
% xlim([0 36000]);
%%
remainBattery =  zeros(1,length(users));
for iu = 1:length(users)
    remainBattery(iu) = users(iu).BatteryLevel;
end
figure;cdfplot(remainBattery);
title('Remaining battery of all UEs');
%%
deathCnt = 0;
distanceOfDeathUE =  zeros(1,length(users));
clockOfDeathUE = zeros(1,length(users));
for iu = 1:length(users)
    if strcmpi(users(iu).Status,'death')
        deathCnt = deathCnt + 1;
        distanceOfDeathUE(deathCnt) = norm(users(iu).Position);
        clockOfDeathUE(deathCnt) = users(iu).Clock;
    end
end
distanceOfDeathUE(deathCnt+1:end) = [];
clockOfDeathUE(deathCnt+1:end) = [];
figure;cdfplot(clockOfDeathUE);
title('Clock of death UEs');
figure;cdfplot(distanceOfDeathUE);
title('Distance of death UEs');
%%
size(cooperationManager.HelpLog)
sum(cooperationManager.HelpLog(3,:)==-1)
%% analyze the log 
foundHelpee = false;
for iu = 1:numUsers
    user = users(iu);
    for il = 1:length(user.Log)
        logEntry = user.Log(il);
        if strcmpi(logEntry.Event,'helpee')
            foundHelpee = true;
            break
        end
    end
    if foundHelpee
        break
    end
end

%% logEntryHelper
for il = 1:length(logHelper)
    logEntryHelper = logHelper(il);
    if logEntryHelper.ID == 1
        break
    end
end
%% 
figure;
hold on
h = cdfplot(deathClockCoop);
set(h,'color','r');
h = cdfplot(deathClockNoncoop);
set(h,'color','b');
xlim([0 36000]);
%%
figure;
hist(deathClockCoop,1000)
figure;
hist(deathClockNoncoop,1000);
