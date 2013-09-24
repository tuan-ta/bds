classdef LTECell < handle
% Class representing an LTE cell
%   properties
%       radius
%       type: circular or hexagonal

    properties (SetAccess = private)
        Radius
        Type
    end
    
    methods        
        function C = LTECell(rad, type)
            switch lower(type)
                case 'circular'
                    C.Radius = rad;
                    C.Type = type;
                case 'hexagonal'
                    error('Hexagonal cell is not yet implemented.');
                otherwise
                    error('Cell type has to be either circular or hexagonal.');
            end
        end
        
        function pos = randomPosition(C)
            switch lower(C.Type)
                case 'circular'            
                    [x y] = pol2cart(random('unif',0,2*pi),C.Radius*sqrt(random('unif',0,1)));
                    pos = [x y];
                case 'hexagonal'
                    error('Hexagonal cell is not yet implemented.');
                otherwise
                    error('Cell type has to be either circular or hexagonal.');
            end            
        end
    end
end