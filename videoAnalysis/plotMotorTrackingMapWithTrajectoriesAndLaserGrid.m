setupFolder = 'J:\20170221\setup 2';
stimFolder = 'J:\20170221\stim 4\front';

cd(setupFolder);

[~,lastDir] = fileparts(setupFolder);

gridFig = open([lastDir '_laser_grid.fig']);

bigFig = figure;

ax = subplot(3,2,1);
colormap(gray);
daspect([1 1 1]);
set(ax,'XTick',[],'YTick',[],'YDir','reverse');
xlim(ax,[0 640]);
ylim(ax,[0 512]);

copyobj(get(get(gridFig,'Children'),'Children'),ax);

cd(stimFolder);

[~,lastDir] = fileparts(stimFolder);

load([lastDir '_motion_tracking.mat']);

%%

if ~exist('pathLengths','var')
    pathLengths = cell2mat(cellfun(@(t) sum(sqrt(sum(diff(t(~any(any(isnan(t),2),3),:,:),[],1).^2,2)),1),trajectories,'UniformOutput',false));
end

mmppx = [0.06730769230769230769230769230769 0.06958250497017892644135188866799]; % TODO : save this somewhere
pathLengthsMM = bsxfun(@times,pathLengths,reshape(mmppx,1,1,2));

%%

[~,bestStim] = max(pathLengths(:));
[l,t,r] = ind2sub(size(pathLengths),bestStim);

load(sprintf('VT%d.mat',l-1));

%%

plotMotionTrackingWithVideo(VT(1),trajectories(l,t),sprintf('%s_VT%d_best_stim_trajectory',lastDir,l-1));