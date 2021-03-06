clc
close all
clear classes

rng('shuffle');
%% create cell
macroCell = LTECell(300,'circular');
cooperationManager = CooperationManager();
recordManager = RecordManager();

%% create users
% There are 3 parameters that need to be initialized
%   1. UE location: uniform is a good choice
%   2. UE battery
%   3. UE data rate
%
%   UE battery and UE data rate are "dual" of each other. Fixing the
%   battery capacity, high initial battery is equivalent to low data rate;
%   low initial battery is equivalent to high data rate.
%
%   In the ICC paper, battery is initialized uniform random from low
%   cooperative threshold to capacity. This allows all UEs full chance to
%   cooperate. Data rate is the same for all UEs.
%
%   An alternative way would be initializing battery to full capacity, and
%   choose data rate from a distribution.
%
%   Yet another alternative that was experimented with is to initialize UEs
%   at different time and keep track of their expected usage time. The
%   problem with this method is that since UEs wake up at different times,
%   the number cooperative UEs is small.

numUsers = SimulationConstants.NumUEs;
for iUser = 1:numUsers
    user = LTEUser(iUser,macroCell);
    user.assignCoopManager(cooperationManager);
    user.assignRecordManager(recordManager);
    users(iUser) = user;
end
cooperationManager.assignUsers(users);

%% run simulation
activeUserList = true(1,numUsers);
tic
simTime = SimulationConstants.SimTime_h*3600e3/SimulationConstants.SimTimeTick_ms;
for t = 1:simTime    
    for iUser = find(activeUserList)
        user = users(iUser);
        user.clockTick();
%         if strcmpi(user.StatusCoop,'stopped') || ...
%                 (strcmpi(user.StatusCoop,'death') && strcmpi(user.StatusNoncoop,'death'))
%             activeUserList(iUser) = false;
%         end
    end
end
simulTime = toc

simulConstants = SimulationConstants.toStruct();

% save simulation record
fn = sprintf('data/%gh_%gh_%g_%g_%gmJ_%g_%g_%s_%g_%g_%g_%g_%g.mat',...
             simulConstants.SimTime_h,...
             simulConstants.MaxTargetUsage_h,...
             simulConstants.MinTargetUsageLevel,...
             simulConstants.MaxTargetUsageLevel,...
             simulConstants.BatteryCapacity_mJ,...
             simulConstants.MaxBatteryLevel,...
             simulConstants.MinBatteryLevel,...
             simulConstants.UtilityType,...
             simulConstants.HighThreshold,...
             simulConstants.LowThreshold,...
             simulConstants.NumUEs,...
             macroCell.Radius,...
             simulConstants.CooperationFlag);
% save(fn);

% run simulation with animation
% simAnimate(users,macroCell);