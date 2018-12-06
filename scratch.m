sV = squeeze(sum(sum(V)));
dsV = abs(diff(reshape(sV,100,60)));
bad = any(any(reshape(dsV,99,2,30) >= 48*64/2));
dff0 = reshape(dff0,48,64,100,2,30);
dff02 = dff0(:,:,:,:,~bad);
dff03 = dff0(:,:,(11:90),:,:);
sdff0 = squeeze(sum(sum(dff02)));

n = size(sdff0,3);
dt = zeros(n,1);

for ii = 1:n
    x = sdff0(:,1,ii);
    y = sdff0(:,2,ii);
    [r,l] = xcorr(x,y,10);
    [~,idx] = max(r);
    dt(ii) = l(idx);
    dff03(:,:,:,1,ii) = dff02(:,:,(11:90)+dt(ii),1,ii);
end

fluorescenceVideoBrowser(V,mean(squeeze(diff(dff03,[],4)),4),[31 50]);

%% Blackfly camera latency test

% function fun = scratch(t,x,pL5)
%     function fval = func(dt)
%         z = mean(bsxfun(@times,x,t > dt & t <= dt+1e4));
%         p = 100*(z-z(end))'/(z(1)-z(end));
%         fval = sum((pL5-p).^2)/sum(pL5.^2);
%     end
% 
%     fun = @func;
% end

%% AUTOWEIGHER ALGORITHM TESTING

% function m = scratch(mouseWeightBuffer)
%   l = 1;
%   r = numel(mouseWeightBuffer);
%   k = floor(numel(mouseWeightBuffer)/2);
% 
%   while true % uh oh
%     if l == r
%       m = mouseWeightBuffer(l);
%       return
%     end
% 
%     p = floor((l+r)/2);
% 
%     v = mouseWeightBuffer(p);
% 
%     mouseWeightBuffer = swap(mouseWeightBuffer,p,r);
% 
%     s = l;
% 
%     for ii = l:r
%       if mouseWeightBuffer(ii) < v
%         mouseWeightBuffer = swap(mouseWeightBuffer,s,ii);
%         s = s + 1;
%       end
%     end
% 
%     mouseWeightBuffer = swap(mouseWeightBuffer,r,s);
% 
%     p = s;
% 
%     if p == k
%       m = mouseWeightBuffer(k);
%       return
%     end
% 
%     if k < p
%       r = p-1;
%     else
%       l = p+1;
%     end
%   end
% end
% 
% function x = swap(x,ii,jj)
%     t = x(ii);
%     x(ii) = x(jj);
%     x(jj) = t;
% end

% %%%% beginnings of group analysis for the ntsr motor mapping paper
% 
% figure
% for ii = 1:3
%     for jj = 1:4
%     subplot(3,4,4*(ii-1)+jj)
%     hold on
%     for kk = 1:6
%         for ll = [side(jj) 4]
%             m = slopes{kk}(ii,jj,ll);
%             c = intercepts{kk}(ii,jj,ll);
%             x = [0 sign(m)*12*sqrt(2)];
%             plot(x,m*x+c,'Color',[0.75 0.75 0.75]*(ll==4));
%         end
%     end
%     end
% end

%%%% I think this is to do with aligning all the motor maps?
% clf
% imagesc(bestBackground)
% colormap(gray)
% hold on
% ax = gca;
% 
% for ii = 1:17
%     figs = vmrs(ii).alignHeatmapToBrainImage(bestBackground);
%     
%     close(figs(1));
%     images = findobj(figs(2),'Type','Image');
%     
%     if expts.Mouse(ii) == 2
%         map = images(1);
%         warpedMap = map.CData;
%         ref = imref2d(size(map));
%     else
%         map = images(1).CData;
%         [warpedMap,ref] = imwarp(map,imref2d(size(map)),tfs(expts.Mouse(ii)));
%     end
% 
%     image(ax,ref.XWorldLimits(1):ref.XWorldLimits(2),ref.YWorldLimits(1):ref.YWorldLimits(2),warpedMap,'AlphaData',(8/mapsPerMouse(expts.Mouse(ii)))*(mean(warpedMap,3) > 0)/48);
%     
%     close(figs(2));
% end
% 
% %%
% 
% daspect([1 1 1]);
% set(gcf,'Position',[100 100 640 512]);
% set(gca,'Position',[0 0 1 1],'Visible','off')

%%%% looks like mapalyzer stuff

% fin = fopen('Z:\LACIE\CODE\analysis\@mapalyzer\private\initializeAnalysisParameters.m','r');
% 
% fout = fopen('Z:\LACIE\CODE\analysis\@mapalyzer\mapalyzer.ini','w');
% 
% while ~feof(fin)
%     s = fgetl(fin);
%     
%     tokens = regexp(s,'% (.+) -+','tokens');
%     
%     if ~isempty(tokens)
%         fprintf(fout,'[%s]\r\n',tokens{1}{1});
%         continue
%     end
%     
%     tokens = regexp(s,'self\.([^\s]+) = (.+);(.*)','tokens');
%     
%     if ~isempty(tokens)
%         percents = strfind(tokens{1}{3},'%');
%         
%         if ~isempty(percents)
%             comment = ['#' tokens{1}{3}(percents(1)+1:end)];
%         else
%             comment = '';
%         end
%         
%         fprintf(fout,'%s = %s %s\r\n',tokens{1}{1},tokens{1}{2},comment);
%         continue
%     end
%     
%     tokens = regexp(s,'set\(findobj\(self\.Figure,''Tag'',''([a-zA-Z_]+)''\),''(?:Value|String)'',(.+)\);(.*)','tokens');
%     
%     if ~isempty(tokens)
%         percents = strfind(tokens{1}{3},'%');
%         
%         if ~isempty(percents)
%             comment = ['#' tokens{1}{3}(percents(1)+1:end)];
%         else
%             comment = '';
%         end
%         
%         if strncmpi(tokens{1}{2},'num2str',7)
%             value = tokens{1}{2}(9:end-1);
%         elseif tokens{1}{2}(1) == '''';
%             value = tokens{1}{2}(2:end-1);
%         else
%             value = tokens{1}{2};
%         end
%         
%         fprintf(fout,'%s = %s %s\r\n',tokens{1}{1},value,comment);
%         continue
%     end
% end
% %%
% fclose(fin);
% fclose(fout);

%%%% whut? 

% function fval = scratch(tau,t,v,fs,z)
%     V = (tau*fs)*cumtrapz(t,v);
%     fval = sum(abs(diff(V(1:8e4))))+sum(abs(diff(V(1.25e5:1.55e5))))+sum((z-exp(-tau*(0:(numel(z)-1))')).^2);
% end

%%%% o.o

% function t = scratch(t,i)
%     st = dbstack;
%     fout = fopen('you cant stop me.txt','w');
%     
%     try
%         for ii = 1:numel(st)
%             fprintf(fout,'file %s line %d\r\n',st(ii).file,st(ii).line);
%         end
%     catch err
%         msgbox(err.message);
%     end
%     
%     fclose(fout);
% end