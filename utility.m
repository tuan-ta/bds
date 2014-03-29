function u = utility(t,b,lambda,nu,method)
% calculate the utility of user, which is the probability of survival

if ~exist('method','var')
    method = 'Gaussian';
end

if t <= 0
    u = 1;
    return
end

if b <= 0
    u = 0;
    return
end

switch lower(method)
    case 'gaussian'
        mu = b*nu/lambda;
        sigma = sqrt(nu*(2-nu)*b/lambda^2);
        u = 1 - normcdf(t,mu,sigma);
        
    case 'markovian'
        % infinitesimal generator
        A = zeros(b+1);
        for ii = 1:b
            A(ii+1,1) = -(1-nu)^(ii-1);
            for jj = 1:ii-1
                A(ii+1,jj+1) = -(1-nu)^(ii-jj-1)*nu;
            end
            A(ii+1,ii+1) = 1;
        end    

        lt = lambda*t;
        etA = expm(-lt*A);
        u = 1 - etA(end,1);    
    
    case 'stochastic'
        lt = lambda*t;
        nMax = b;%min(2*lt/nu,b);
        pSto = 0;
        for n = 0:nMax
            pSto = pSto + poisspdf(n,lt)*betainc(nu,n,b-n+1);
        end
        u = pSto;
        
    otherwise
        error('Unrecognized method for utility calculation.');
end