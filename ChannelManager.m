classdef ChannelManager
% ChannelManager calculates path loss depend on the type of link according
% to WINNER II channel models.
% It is assumed that the user position has already been updated

    methods (Static)
        function pl_dB = pathloss(users,linkType)
            DEBUG = false;            
            switch lower(linkType)
                case 'u2e' % WINNER II model C2
                    if length(users)~=1
                        error('U2E link type should only have 1 UE.');
                    end
                    d = norm(users.Position);
                    hBS = SimulationConstants.BSAntennaHeight_m;
                    hMS = SimulationConstants.UEAntennaHeight_m;
                    fc = SimulationConstants.CarrierFrequency_Hz;
                    dpBP = 4*(hBS-1)*(hMS-1)*fc/3e8;
                    pLOS = min(18/d,1)*(1-exp(-d/63)) + exp(-d/63); % probablity of link being LOS
                    flagLOS = rand < pLOS;
                    if d < 50 % hack because WINNER II C2 model NLOS doesn't apply for d < 50m
                        flagLOS = true; 
                    end
                    if flagLOS
                        if d < 10
                            pl_dB = 0;                            
                        elseif d < dpBP                            
                            pl_dB = 26*log10(d) + 39 + 20*log10(fc*1e-9/5) + 4*randn;                            
                        else
                            pl_dB = 40*log10(d) + 13.47 - 14*log10(hBS-1) -...
                                14*log10(hMS-1) + 6*log10(fc*1e-9/5) + 6*randn;
                        end
                    else % NLOS
                        pl_dB = (44.9-6.55*log10(hBS))*log10(d) + 34.46 + ...
                            5.83*log10(hBS) + 23*log10(fc*1e-9/5) + 8*randn;
                    end
                    if DEBUG
                        fprintf('U2E path loss for user %g: %g\n',users.ID,pl_dB);
                    end
                case 'd2d' % WINNER II model A1
                    if length(users)~=2
                        error('D2D link type should have 2 UEs.');
                    end
                    d = norm(users(1).Position - users(2).Position);
                    if d > 100
                        warning('WINNER II indoor channel model doesn''t support distance greater than 100m. The current distance is %g.',d);
                        users(1)
                        users(2)
                    end
                    fc = SimulationConstants.CarrierFrequency_Hz;
                    if d < 2.5
                        pLOS = 1;
                    else
                        pLOS = 1 - 0.9*(1-(1.24-0.61*log10(d))^3)^(1/3);
                    end
                    flagLOS = rand < pLOS;
                    if flagLOS
                        pl_dB = 18.7*log10(d) + 46.8 + 20*log10(fc*1e-9/5) + 3*randn;
                    else
                        pl_dB = 36.8*log10(d) + 43.8 + 20*log10(fc*1e-9/5) + ...
                            5*(SimulationConstants.NumWallsIndoorNLOS-1) + 4*randn;
                    end
                    if DEBUG
                        fprintf('D2D path loss between helpee %g and helper %g: %g\n',users(1).ID,users(2).ID,pl_dB);                        
                    end
                otherwise
                    error('linkType should be U2E or D2D.');
            end
        end 
    end
end