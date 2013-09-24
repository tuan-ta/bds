%%
deathClock = zeros(1,length(users));
for iu = 1:length(users)
    deathClock(iu) = users(iu).Clock;
end
figure;cdfplot(deathClock)
title('Final clock of all UEs');
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
%%
figure;
hold on
h = cdfplot(deathClock_coop);
set(h,'color','r');
h = cdfplot(deathClock_noncoop);
set(h,'color','b');