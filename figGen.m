function figGen(usageTimeCoop,usageTimeNoncoop,printFlag)
% figGen generates figures for pulication
%   figGen(usageTimeCoop,usageTimeNoncoop,[printFlag]) generates CDF and
%   PDF plots for the usage time. Usage time data is assumed to be given in
%   unit of hours.

    % sanity check
    if ~isequal(size(usageTimeCoop),size(usageTimeNoncoop))
        error('Data size mismatch.');
    end
    
    if ~exist('printFlag','var')
        printFlag = false;
    end

    % CDF of usage time
    figure;
    hold on
    h = cdfplot(usageTimeCoop);
    set(h,'color','r','linewidth',2);
    h = cdfplot(usageTimeNoncoop);
    set(h,'color','b','linewidth',2,'linestyle','--');
    title('CDF of usage time','fontsize',18);
    legend('Coop','Noncoop','location','east');
    xlabel('Time (hours)','fontsize',14);
    ylabel('CDF','fontsize',14);
    set(gca,'fontsize',14);
    xlim([4 20]);
    set(gca,'XTick',[4:2:20]);
    
    if printFlag
        print('-depsc','fig/cdf_usage_time.eps','-r600');
    end
    

    % PDF of usage time (histogram)
    figure;
    hist(usageTimeCoop,50);    
    h1 = findobj(gca,'type','patch');
    set(h1,'FaceColor','r','EdgeColor','w','FaceAlpha',0.75);    
    hold on
    hist(usageTimeNoncoop,50);
    h = findobj(gca,'type','patch');
    set(h,'FaceAlpha',0.75);
    title('Histogram of usage time','fontsize',18);
    legend('Coop','Noncoop','location','northeast');
    xlabel('Time (hours)','fontsize',14);
    ylabel('CDF','fontsize',14);
    set(gca,'fontsize',14);
    xlim([4 20]);
    set(gca,'XTick',[4:2:20]);
    
    if printFlag
        print('-depsc','fig/pdf_usage_time.eps','-r300');
    end   