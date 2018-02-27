clf
imagesc(bestBackground)
colormap(gray)
hold on
ax = gca;

for ii = 1:17
    figs = vmrs(ii).alignHeatmapToBrainImage(bestBackground);
    
    close(figs(1));
    images = findobj(figs(2),'Type','Image');
    
    if expts.Mouse(ii) == 2
        map = images(1);
        warpedMap = map.CData;
        ref = imref2d(size(map));
    else
        map = images(1).CData;
        [warpedMap,ref] = imwarp(map,imref2d(size(map)),tfs(expts.Mouse(ii)));
    end

    image(ax,ref.XWorldLimits(1):ref.XWorldLimits(2),ref.YWorldLimits(1):ref.YWorldLimits(2),warpedMap,'AlphaData',(8/mapsPerMouse(expts.Mouse(ii)))*(mean(warpedMap,3) > 0)/48);
    
    close(figs(2));
end

%%

daspect([1 1 1]);
set(gcf,'Position',[100 100 640 512]);
set(gca,'Position',[0 0 1 1],'Visible','off')

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

% function fval = scratch(tau,t,v,fs,z)
%     V = (tau*fs)*cumtrapz(t,v);
%     fval = sum(abs(diff(V(1:8e4))))+sum(abs(diff(V(1.25e5:1.55e5))))+sum((z-exp(-tau*(0:(numel(z)-1))')).^2);
% end

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