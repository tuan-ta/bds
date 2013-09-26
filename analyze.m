%%
fn = sprintf('data/coop_%gh_%gms_%gB_%gmJ_0101_3.mat',...
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
figure;
hist(deathClock,1000);
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
%% combine coop and noncoop data from multiple mat files
deathClockCoop = [];
for ii = 1:3
    fn = sprintf('data/coop_%gh_%gms_%gB_%gmJ_0101_%g.mat',...
        SimulationConstants.SimTime_h,...
        SimulationConstants.SimTimeTick_ms,...
...%     SimulationConstants.InterBurstArrival_s,...
        SimulationConstants.MeanBurstSize_bytes,...
        SimulationConstants.BatteryCapacity_mJ,...
        ii);
    load(fn,'users');
    deathClock = zeros(1,length(users));
    for iu = 1:length(users)
        deathClock(iu) = users(iu).Clock;
    end
    deathClockCoop = [deathClockCoop deathClock];
end
deathClockNoncoop = [];
for ii = 1:3
    fn = sprintf('data/noncoop_%gh_%gms_%gB_%gmJ_0101_%g.mat',...
        SimulationConstants.SimTime_h,...
        SimulationConstants.SimTimeTick_ms,...
...%     SimulationConstants.InterBurstArrival_s,...
        SimulationConstants.MeanBurstSize_bytes,...
        SimulationConstants.BatteryCapacity_mJ,...
        ii);
    load(fn,'users');
    deathClock = zeros(1,length(users));
    for iu = 1:length(users)
        deathClock(iu) = users(iu).Clock;
    end
    deathClockNoncoop = [deathClockNoncoop deathClock];
end
figure;
hold on
h = cdfplot(deathClockCoop);
set(h,'color','r');
h = cdfplot(deathClockNoncoop);
set(h,'color','b');
xlim([0 36000]);

%% 
deathCnt = 0;
stoppedCnt = 0;
deathClock = zeros(1,length(users));
stoppedBattery = zeros(1,length(users));
for iu = 1:numUsers
    user = users(iu);
    if strcmpi(user.Status,'death')
        deathCnt = deathCnt + 1;
        deathClock(deathCnt) = user.Clock-user.StartInstant;
    elseif strcmpi(user.Status,'stopped')
        stoppedCnt = stoppedCnt + 1;
        stoppedBattery(stoppedCnt) = user.BatteryLevel;
    end
end
deathClock(deathCnt+1:end) = [];
stoppedBattery(stoppedCnt+1:end) = [];
figure;
cdfplot(deathClock);
title('Clock of death UEs');
figure;
cdfplot(stoppedBattery);
title('Remaining battery of stopped UEs');
%%
deathClockCoop = [];
stoppedBatteryCoop = [];
for ii = 1:5
    fn = sprintf('data/coop_random_start_1h_6000mJ_0101_%g.mat',ii);
    load(fn,'users');
    deathCnt = 0;
    stoppedCnt = 0;
    deathClock = zeros(1,length(users));
    stoppedBattery = zeros(1,length(users));
    for iu = 1:numUsers
        user = users(iu);
        if strcmpi(user.Status,'death')
            deathCnt = deathCnt + 1;
            deathClock(deathCnt) = user.Clock-user.StartInstant;
        elseif strcmpi(user.Status,'stopped')
            stoppedCnt = stoppedCnt + 1;
            stoppedBattery(stoppedCnt) = user.BatteryLevel;
        end
    end
    deathClock(deathCnt+1:end) = [];
    stoppedBattery(stoppedCnt+1:end) = [];
    deathClockCoop = [deathClockCoop deathClock];
    stoppedBatteryCoop = [stoppedBatteryCoop stoppedBattery];
end
load('data/noncoop_random_start_1h_6000mJ.mat','users');
deathCnt = 0;
stoppedCnt = 0;
deathClock = zeros(1,length(users));
stoppedBattery = zeros(1,length(users));
for iu = 1:numUsers
    user = users(iu);
    if strcmpi(user.Status,'death')
        deathCnt = deathCnt + 1;
        deathClock(deathCnt) = user.Clock-user.StartInstant;
    elseif strcmpi(user.Status,'stopped')
        stoppedCnt = stoppedCnt + 1;
        stoppedBattery(stoppedCnt) = user.BatteryLevel;
    end
end
deathClock(deathCnt+1:end) = [];
stoppedBattery(stoppedCnt+1:end) = [];

figure;
hold on
h = cdfplot(deathClockCoop);
set(h,'color','r');
h = cdfplot(deathClock);
set(h,'color','b');
figure;
hist(deathClockCoop,50);
title('Coop PDF');
figure;
hist(deathClock,50);
title('Noncoop PDF');