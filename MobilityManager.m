classdef MobilityManager
% MobilityManager class provides methods that implement a listener for the
% event NextMovementEvent of LTEUser object. At event trigger,
% MobilityManager generates the next movement.    

    methods (Static)
        function generateMovement(user)
            DEBUG = false;            
            if user.Speed == 0 % user was pausing, now starts walking
                speed = random('unif',user.MobilityModel.SpeedInterval(1),...
                    user.MobilityModel.SpeedInterval(2));                
                direction = random('unif',0,2*pi);
                walkDuration = random('unif',user.MobilityModel.WalkInterval(1),...
                    user.MobilityModel.WalkInterval(2));
                user.Speed = speed;
                user.Direction = direction;
                user.NextMovementInstant = user.NextMovementInstant + ...
                    round(walkDuration*1000/SimulationConstants.SimTimeTick_ms);
                user.WalkTimeMarker = user.Clock;
            else % user was walking, now starts pausing
                pause = random('unif',user.MobilityModel.PauseInterval(1),...
                    user.MobilityModel.PauseInterval(2));
                user.NextMovementInstant = user.NextMovementInstant + ...
                    max(round(pause*1000/SimulationConstants.SimTimeTick_ms),1);
                user.Speed = 0;
                MobilityManager.updatePosition(user);
            end
%             if SimulationConstants.LoggingFlag
%                 logData(user);
%             end
            if DEBUG
                fprintf('Mobility.generateMovement\n');
                user
            end
        end
        
        function addUser(user)
            addlistener(user,'NextMovementEvent',...
                @(src,evnt)MobilityManager.generateMovement(src));
        end
        
        function updatePosition(user)
        % Calculate new user position based on past position, current
        % speed, direction and walk duration.
        % If the user goes outside his cell boundary, this function makes
        % him "reflect" back within the cell at the boundary crossing point

            prePos = user.Position;
            speed = user.Speed;
            direction = user.Direction;
            duration = (user.Clock - user.WalkTimeMarker)*SimulationConstants.SimTimeTick_ms/1000;
            if duration < 0
                error('Negative duration');
            end
            cell = user.Cell;

            [dx dy] = pol2cart(direction,speed*duration);
            newPos = prePos + [dx dy];

            % check if the new position is outside the cell
            if strcmpi(cell.Type,'circular')
                if norm(newPos) > cell.Radius
                % outside, reflect user back in
                    bound_crossing = bound_xing_pt(prePos,newPos,cell.Radius);
                    dest_after_turn = pol_tangent_image(bound_crossing,newPos,cell.Radius);
                    return_path_vector = dest_after_turn - bound_crossing;
                    [new_direction,dummy] = cart2pol(return_path_vector(1), return_path_vector(2));            
                    user.Direction = new_direction;
                    user.assignPosition(dest_after_turn);
                else
                    user.assignPosition(newPos);
                end
            end            
            
            user.WalkTimeMarker = user.Clock;
        end
    end
end

function b = bound_xing_pt(orig, dest, r)
%find point on circular boundary that is on current path
% -find angle of new direction relative to current position
% -find length of distance traveled in that direction to
% get to the boundary

    [dummy,r_orig] = cart2pol(orig(1),orig(2));
    [dummy,r_dest] = cart2pol(dest(1),dest(2));
    dist = norm(orig-dest);

    angle_at_orig = acos((r_orig^2+dist^2-r_dest^2)/(2*r_orig*dist));
    angle_at_bound = asin(sin(angle_at_orig)*r_orig/r);
    angle_at_center = pi - angle_at_bound - angle_at_orig;
    dist_orig_to_b = r*sin(angle_at_center)/sin(angle_at_orig);
    b = orig + dist_orig_to_b/dist*(dest-orig);
end

function v_im = pol_tangent_image(b, v, r)
% find the mirror image v_im of vector v about the tangent at point b on
% the circle

    if abs(norm(b)-r)>1e-6
        error('b must be on the cirle.');
    end

    [theta_b r_b] = cart2pol(b(1),b(2));
    tangent_angle = theta_b - pi/2;
    if tangent_angle < -pi
        tangent_angle = tangent_angle + 2*pi;
    end
    v_translated = v - b;
    [theta_vt r_vt] = cart2pol(v_translated(1),v_translated(2));
    theta_vr = theta_vt - tangent_angle;
    if theta_vr > pi
        theta_vr = theta_vr - 2*pi;
    elseif theta_vr < -pi
        theta_vr = theta_vr + 2*pi;
    end
    if theta_vr < 0
        error('Vector v should always lie above the tangent.');
    end
    [v_rotated(1) v_rotated(2)] = pol2cart(theta_vr,r_vt);
    v_im_transformed = v_rotated.*[1 -1];
    [theta_vit r_vit] = cart2pol(v_im_transformed(1),v_im_transformed(2));
    theta_vi = theta_vit + tangent_angle;
    [v_im_translated(1) v_im_translated(2)] = pol2cart(theta_vi,r_vit);
    v_im = v_im_translated + b;
end

function logData(user)
% record mobility data

    mobilityData = struct('Time',user.Clock,...
                          'Event','Mobility',...
                          'Details',struct('Speed',user.Speed,...
                                           'Direction',user.Direction,...
                                           'NextMovementInstant',user.NextMovementInstant));
    user.Log = [user.Log mobilityData];
end