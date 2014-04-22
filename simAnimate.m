function simAnimate(users,simCell)
% simAnimate  Simulation animation
%   simAnimate(users,simCell) displays traces of users' movement within the
%   simCell.

    numUsers = length(users);
    simTime = SimulationConstants.SimTime_h*3600e3/SimulationConstants.SimTimeTick_ms;
    activeUserList = true(1,numUsers);

    figure;    
    hold on
    plot(0,0,'rv','MarkerFaceColor','r');
    for iUser = 1:numUsers
        vh_user_pos(iUser) = plot(users(iUser).Position(1),users(iUser).Position(1),'*','color','b');
    end
    xlabel('X (meters)');
    ylabel('Y (meters)');
    title('Battery Deposit Service');
    xc = linspace(-simCell.Radius,simCell.Radius);
    yc = sqrt(simCell.Radius^2 - xc.^2);
    plot(xc,yc);
    plot(xc,-yc);
    ht = text(-simCell.Radius,simCell.Radius,cat(2,'Time (sec) = 0'));
    axis([-simCell.Radius simCell.Radius -simCell.Radius simCell.Radius]);
    axis square
    
    xcHelp = linspace(-SimulationConstants.HelpRange_m,SimulationConstants.HelpRange_m);
    ycHelp = sqrt(SimulationConstants.HelpRange_m^2 - xcHelp.^2);
    helpCirclePos = plot(zeros(size(xcHelp)),zeros(size(ycHelp)),'r');
    helpCircleNeg = plot(zeros(size(xcHelp)),zeros(size(ycHelp)),'r');
    hold off
    for it = 1:simTime
        t = it*SimulationConstants.SimTimeTick_ms/1000;
        set(ht,'String',cat(2,'Time (sec) = ',num2str(t,4)));
        set(helpCirclePos,'XData',zeros(size(xcHelp)),'YData',zeros(size(ycHelp)));
        set(helpCircleNeg,'XData',zeros(size(xcHelp)),'YData',zeros(size(ycHelp)));
        for iUser = find(activeUserList)
%             if ~isempty(users(iUser).CoopManager.HelpeeID) && users(iUser).CoopManager.HelpeeID==users(iUser).ID
%                 set(helpCirclePos,'XData',xcHelp + users(iUser).Position(1),'YData',ycHelp + users(iUser).Position(2));
%                 set(helpCircleNeg,'XData',xcHelp + users(iUser).Position(1),'YData',-ycHelp + users(iUser).Position(2));
%             end 
            users(iUser).clockTick();
            MobilityManager.updatePosition(users(iUser));
            set(vh_user_pos(iUser),'XData',users(iUser).Position(1),'YData',users(iUser).Position(2));
            if strcmpi(users(iUser).Status,'death')
                set(vh_user_pos(iUser),'color','r');
            elseif strcmpi(users(iUser).Status,'stopped')
                set(vh_user_pos(iUser),'color','c');            
            end
            if strcmpi(users(iUser).Status,'stopped') || ...
                    strcmpi(users(iUser).Status,'death')
                activeUserList(iUser) = false;
            end
        end
        drawnow; pause(0.05);
    end
end