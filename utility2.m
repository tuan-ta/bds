function u = utility2(t,b,lambda,nu)
% calculate the utility of user as the expected valued usage time

if t <= 0
    u = 1;
    return
end

if b <= 0
    u = 0;
    return
end

muT = b*nu/lambda;
sigmaT = sqrt(nu*(2-nu)*b/lambda^2);
% u = sigmaT/sqrt(2*pi)*(exp(-muT^2/(2*sigmaT^2)) - ...
%                        exp(-(t-muT)^2/(2*sigmaT^2))) + ...
%     t - muT*normcdf(-muT/sigmaT) + (muT-t)*normcdf((t-muT)/sigmaT);
u = sigmaT/sqrt(2*pi)*(exp(-muT^2/(2*sigmaT^2)) - ...
                       exp(-(t-muT)^2/(2*sigmaT^2))) + ...
    t - (t - muT)*normcdf((t-muT)/sigmaT);
u = u/t;

% Gaussian approximation is not very accurate near extreme points
if u > 1
    u = 1;
end