clc
clear all
clear classes

%% create cell
macroCell = LTECell(500,'circular');
cooperationManager = CooperationManager();

%% create users
numUsers = 500;
for iUser = 1:numUsers
    user = LTEUser(iUser);
    user.assignCell(macroCell);
    user.assignPosition(macroCell.randomPosition());
    user.assignCoopManager(cooperationManager);
    users(iUser) = user;
end

%% run simulation
tic
simTime = SimulationConstants.SimTime_h*3600e3/SimulationConstants.SimTimeTick_ms;
for t = 1:simTime    
    for iUser = 1:numUsers
        user = users(iUser);
        user.clockTick();
    end
end
% simAnimate(users,macroCell);
toc
%% analyze result