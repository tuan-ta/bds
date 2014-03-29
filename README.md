bds
===

# Battery Deposit Service simulator

This simulator intends to verify the performance of the Battery Deposit Service (BDS).
[ICC 2014]: git commit 74a183760a905383502fe9acc1c4218a5d19d456

-----------------------------

## Requirements

* Matlab (tested with Matlab 2008)

## An example


```
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
simTime = SimulationConstants.SimTime_h*3600e3/SimulationConstants.SimTimeTick_ms;
for t = 1:simTime
    for iUser = 1:numUsers
        user = users(iUser);
        user.clockTick();
    end
end
```

To visualize the simulation

```
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
simAnimate(users,macroCell);
```

## Components of the simulator

### LTEUser

Class for a user object. This class has 2 events: `BurstArrives` and `NextMovementEvent` which trigger the TrafficManager and MobilityManager respectively.

### LTECell

Class for a cell. This class has a method to provide a random position within the cell. This method can be used to initialize the simulation.

### TrafficManager

Listens to the 'BurstArrives' event. Once the event is triggered, TrafficManager simulates the consumption of the current burst using path loss values from the ChannelManager and cooperation setting from the CooperationManager. TrafficManager then generates the next data burst (arrival instant and burst size).

### ChannelManager

Implements WINNER II urban marco-cell channel model for UE to eNodeB (U2E) link and WINNER II indoor channel model for device-to-device D2D link.

### MobilityManager

Implements Random Duration Model. Speed, pause duration and walk duration are drawn uniformly within their respective ranges.

### CooperationManager

Implements helper selection algorithm.

### SimulationConstants

Class to hold constants used in the simulation.

