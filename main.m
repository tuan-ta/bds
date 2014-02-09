clc
clear classes

clk = clock;
% randseed = round(79*clk(4) + 37*clk(5) + clk(6))

% diary(sprintf('log_%g.txt',randseed));
% SimulationConstants
% rng(randseed);
rng('shuffle');

%% create cell
macroCell = LTECell(300,'circular');
cooperationManager = CooperationManager();

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
%   In the paper, battery is initialized uniform random from low
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
% startInstants = random('unif',0,SimulationConstants.SimDay_h*3600e3/SimulationConstants.SimTimeTick_ms,...
%     1,numUsers);
% stopInstants = startInstants + SimulationConstants.SimExpectedUsage_h*3600e3/SimulationConstants.SimTimeTick_ms;
startInstants = zeros(1,numUsers);
stopInstants = startInstants + SimulationConstants.SimTime_h*3600e3/SimulationConstants.SimTimeTick_ms;
for iUser = 1:numUsers
    user = LTEUser(iUser);
    user.assignCell(macroCell);
    user.assignPosition(macroCell.randomPosition());
    user.assignCoopManager(cooperationManager);
    user.assignParticipateInstants(startInstants(iUser),stopInstants(iUser));
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
        if strcmpi(user.StatusCoop,'stopped') || ...
                (strcmpi(user.StatusCoop,'death') && strcmpi(user.StatusNoncoop,'death'))
            activeUserList(iUser) = false;
        end
    end
end
toc

simulConstants = SimulationConstants.toStruct();

% save(sprintf('data/24h_300e3mJ_multiple_user_classes_%g.mat',randseed));

% run simulation with animation
% simAnimate(users,macroCell);

% diary off