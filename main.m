clc
clear classes

clk = clock;
randseed = round(79*clk(4) + 37*clk(5) + clk(6));

diary(sprintf('log_%g.txt',randseed));
SimulationConstants
rng(randseed);

%% create cell
macroCell = LTECell(500,'circular');
cooperationManager = CooperationManager();

%% create users
% pos = [50 0];
numUsers = 500;
% startInstants = random('unif',0,SimulationConstants.SimDay_h*3600e3/SimulationConstants.SimTimeTick_ms,...
%     1,numUsers);
% stopInstants = startInstants + SimulationConstants.SimExpectedUsage_h*3600e3/SimulationConstants.SimTimeTick_ms;
startInstants = zeros(1,numUsers);
stopInstants = startInstants + SimulationConstants.SimTime_h*3600e3/SimulationConstants.SimTimeTick_ms;
for iUser = 1:numUsers
    user = LTEUser(iUser);
    user.assignCell(macroCell);
    user.assignPosition(macroCell.randomPosition());
%     user.assignPosition(pos + 10*(rand(1,2)-0.5));
    user.assignCoopManager(cooperationManager);
    user.assignParticipateInstants(startInstants(iUser),stopInstants(iUser));
    users(iUser) = user;
end

%% run simulation
activeUserList = true(1,numUsers);
tic
simTime = SimulationConstants.SimTime_h*3600e3/SimulationConstants.SimTimeTick_ms;
for t = 1:simTime    
    for iUser = find(activeUserList)
        user = users(iUser);
        user.clockTick();
        if strcmpi(user.StatusCoop,'stopped') || ...
                (strcmpi(user.StatusCoop,'death') && strcmpi(user.StatusNoncoop,'death'))
            activeUserList(iUser) = false;
        end
    end
end
toc

simulConstants = SimulationConstants.toStruct();

save(sprintf('data/24h_300e3mJ_random_starting_battery_from_lowthreshold_%g.mat',randseed));

% simAnimate(users,macroCell);

diary off