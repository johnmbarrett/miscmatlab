%%% Ctrl+Enter to run blocks of code surrounded in double percent signs %%%

%% CHOOSE FOLDER;

folder = pwd; % or specify
cd(folder);

[stimFolder,finalFolder] = fileparts(folder);
[exptFolder,stimFolder] = fileparts(stimFolder);

%% RETRIEVE LIST OF VIDEO FILES

files = loadFilesInNumericOrder('VT*.mat','VT([0-9])+\.mat');
n = numel(files);

%% DO Z-SCORE ANALYSIS - COARSE

calculateAverageMovement(files,ceil(sqrt([n n])),1:9,2/(2*ceil(sqrt(n))/7+4/7),[],'',false,false,true);

%% PLOT Z-SCORE MAP - COARSE

load([finalFolder '_movement.mat']);
figure;
imagesc(movement);
saveas(gcf,[finalFolder '_zscore'],'fig');
close(gcf);

%% SET PARAMETERS FOR SINGLE-ROI Z-SCORE ANALYSIS

bodyPart = 'left_forepaw'; % change as appopriate

%% DO Z-SCORE ANALYSIS - SINGLE ROI

load(files{1});
imagesc(VT{1}(:,:,1));
roi = imrect;
pos = round(getPosition(roi));
pos = [pos(2) pos(2)+pos(4) pos(1) pos(1)+pos(3)];

calculateAverageMovement(vtFiles,ceil(sqrt([n n])),1:9,2/(2*ceil(sqrt(n))/7+4/7),pos,bodyPart,false,false,true);

%% PLOT Z-SCORE MAP - SINGLE ROI

load([finalFolder '_' bodyPart '_movement.mat']);
figure;
imagesc(movement);
saveas(gcf,[finalFolder '_' bodyPart '_zscore'],'fig');
close(gcf);

%% DO MOTION TRACKING ANALYSIS

motorTrackingMap(files);

%% LOAD MOTION TRACKING DATA

load([finalFolder '_motion_tracking.mat']);

%% ALIGN MAP TO BRAIN

rows = ceil(sqrt(n)); % TODO : specify this properly
cols = ceil(sqrt(n)); % TODO : specify this properly
setupFolder = 'setup 3';
blankImage = 1;
manualBlobDetection = false;

laserGridFile = [exptFolder '\' setupFolder '\' setupFolder '_laser_grid.mat'];

if exist(laserGridFile,'file')
    cd([exptFolder '\' setupFolder]);
    
    load(laserGridFile,'beta');
else
    cd(exptFolder);
    
    [grid,beta] = fitGridToSpots(rows,cols,setupFolder,blankImage,manualBlobDetection); % TODO : this needs to be more robust
end

bmps = dir('*.bmp');
%%
open([laserGridFile(1:end-3) 'fig']);
daspect([1 1 1]);
%%
bregma = impoint;
bregmaCoordsPX = getPosition(bregma);

cd(folder);
%%
[figs,alignmentTransform,warpedMaps,imrefs] = alignHeatmapToBrainImage(reshape(map,rows,cols,size(map,2)),[exptFolder '\' setupFolder '\' bmps(blankImage).name],beta);

for ii = 1:numel(figs)
    saveas(figs(ii),sprintf('%s_%s_motor_tracking_map_aligned_to_brain',finalFolder,bodyParts{ii}),'fig')
end

%% PLOT MOTION TRACKING MAP

useRealCoords = true;

switch size(map,2)
    case 2
        bodyParts = {'right_forepaw' 'left_forepaw'};
    case 3
        bodyParts = {'right_forepaw' 'left_forepaw' 'hindpaw'};
    otherwise
        error('Unknown number of ROIs');
end

% bodyParts = {'to specify body parts manually, uncomment this line and enter body parts corresponding to each ROI as a cell array of strings'};

layout = sqrt([n n]);
% layout = [1 1]; % comment out the above line and uncomment this one to specify layout manually
%%
isRowsEven = mod(layout,1) == 0;
xtick = ((1-0.5*isRowsEven):(1+(layout(1) > 9)):(layout(1)+isRowsEven))';

isColsEven = mod(layout,2) == 0;
ytick = ((1-0.5*isColsEven):(1+(layout(2) > 9)):(layout(2)+isColsEven))';

assert(prod(layout) == size(map,1),'Map dimensions must match number of stimulation sites');

mmppxTracking = 0.067; % enter mm per pixel for motion tracking camera here
mmppxAlignment = 0.025; % enter mm per pixel for laser alignment camera here
%%
% [verticalLineX,verticalLineY] = transformPointsInverse(alignmentTransform,[0;1],[0;0]); % vertical line uses the X co-ordinate because the laser alignment image is rotated 90 degrees relative to the map
% verticalLineAngle = atan(diff(verticalLineY)/diff(verticalLineX));
% 
% while abs(verticalLineAngle) > pi/4
%     verticalLineAngle = verticalLineAngle - sign(verticalLineAngle)*pi/2;
% end
% 
% verticalLineTransform = affine2d([cos(verticalLineAngle) -sin(verticalLineAngle) 0; sin(verticalLineAngle) cos(verticalLineAngle) 0; 0 0 1]*[1 0 0; 0 1 0; 10*layout(1)/12 10*layout(2)/12 1]);
% [verticalLineX,verticalLineY] = transformPointsForward(verticalLineTransform,[0;0],[-1.5;1.5]);
% [topArrowX,topArrowY] = transformPointsForward(verticalLineTransform,[0;0.2;-0.2],[-1.7;-1.2;-1.2]);
% [bottomArrowX,bottomArrowY] = transformPointsForward(verticalLineTransform,[0;0.2;-0.2],[1.7;1.2;1.2]);
% [rostralX,rostralY] = transformPointsForward(verticalLineTransform,0,-2);
% [caudalX,caudalY] = transformPointsForward(verticalLineTransform,0,2);
% 
% [horizontalLineX,horizontalLineY] = transformPointsInverse(alignmentTransform,[0;0],[0;1]); % horizontal line uses the Y co-ordinate because the laser alignment image is rotated 90 degrees relative to the map
% horizontalLineAngle = atan(diff(horizontalLineY)/diff(horizontalLineX));
% 
% while abs(horizontalLineAngle) > pi/4
%     horizontalLineAngle = horizontalLineAngle - sign(verticalLineAngle)*pi/2;
% end
% 
% horizontalLineTransform = affine2d([cos(horizontalLineAngle) -sin(horizontalLineAngle) 0; sin(horizontalLineAngle) cos(horizontalLineAngle) 0; 0 0 1]*[1 0 0; 0 1 0; 10*layout(1)/12 10*layout(2)/12 1]);
% [horizontalLineX,horizontalLineY] = transformPointsForward(horizontalLineTransform,[-1.5;1.5],[0;0]);
% [leftArrowX,leftArrowY] = transformPointsForward(horizontalLineTransform,[-1.7;-1.2;-1.2],[0;0.2;-0.2]);
% [rightArrowX,rightArrowY] = transformPointsForward(horizontalLineTransform,[1.7;1.2;1.2],[0;0.2;-0.2]);
% [leftX,leftY] = transformPointsForward(horizontalLineTransform,-2,0);
% [rightX,rightY] = transformPointsForward(horizontalLineTransform,2,0);
% 
% if all(xtick([1 end]) <= 0)
%     leftText = 'L';
%     rightText = 'M';
% elseif all(xtick([1 end]) >= 0)
%     leftText = 'M';
%     rightText = 'L';
% else
%     leftText = 'S';
%     rightText = 'D';
% end

xtickMarksBottom = mmppxAlignment*([ones(size(xtick)) xtick(1)*ones(size(xtick)) flipud(xtick)]*beta(:,2)-bregmaCoordsPX(2));
ytickMarksBottom = mmppxAlignment*([ones(size(ytick)) flipud(ytick) ytick(end)*ones(7,1)]*beta(:,1)-bregmaCoordsPX(1));

xtickMarksTop = mmppxAlignment*([ones(size(xtick)) xtick(end)*ones(size(xtick)) flipud(xtick)]*beta(:,2)-bregmaCoordsPX(2));
ytickMarksTop = mmppxAlignment*([ones(size(ytick)) ytick ytick(1)*ones(size(ytick))]*beta(:,1)-bregmaCoordsPX(1));

xscale = median([median(abs(diff(xtickMarksBottom))) median(abs(diff(xtickMarksTop)))]);
yscale = median([median(abs(diff(ytickMarksBottom))) median(abs(diff(ytickMarksTop)))]);

%%

[lineCenterXr,lineCenterYr] = transformPointsForward(alignmentTransform,10*layout(1)/12,2*layout(2)/12); % TODO : check indices are the right way round

horizontalLineXr = lineCenterXr*[1 1];
horizontalLineYr = lineCenterYr+[-1 1]*beta(2,1); % horizonal line is vertical in imaging space

horizontalLineLength = abs(diff(horizontalLineYr));

verticalLineXr = lineCenterXr+[-1 1]*beta(3,2)*yscale/xscale; % and vice-versa
verticalLineYr = lineCenterYr*[1 1];

verticalLineLength = abs(diff(verticalLineXr));

horizontalArrowheadsXr = repmat(lineCenterXr+[0;-0.1;0.1]*horizontalLineLength/2,1,2);
horizontalArrowheadsYr = [1.1;0.8;0.8]*(horizontalLineYr-lineCenterYr)+lineCenterYr;

verticalArrowheadsXr = [1.1;0.8;0.8]*(verticalLineXr-lineCenterXr)+lineCenterXr;
verticalArrowheadsYr = repmat(lineCenterYr+[0;-0.1;0.1]*verticalLineLength/2,1,2);

rightXr = horizontalLineXr(1);
rightYr = lineCenterYr + 0.7*verticalLineLength;

leftXr = horizontalLineXr(1);
leftYr = lineCenterYr - 0.7*verticalLineLength;

caudalXr = lineCenterXr - 0.7*horizontalLineLength;
caudalYr = verticalLineYr(1);

rostralXr = lineCenterXr + 0.7*horizontalLineLength;
rostralYr = verticalLineYr(1);

[horizontalLineXm,horizontalLineYm] = transformPointsInverse(alignmentTransform,horizontalLineXr,horizontalLineYr);
[verticalLineXm,verticalLineYm] = transformPointsInverse(alignmentTransform,verticalLineXr,verticalLineYr);
[horizontalArrowheadsXm,horizontalArrowheadsYm] = transformPointsInverse(alignmentTransform,horizontalArrowheadsXr,horizontalArrowheadsYr);
[verticalArrowheadsXm,verticalArrowheadsYm] = transformPointsInverse(alignmentTransform,verticalArrowheadsXr,verticalArrowheadsYr);
[rostralXm,rostralYm] = transformPointsInverse(alignmentTransform,rostralXr,rostralYr);
[caudalXm,caudalYm] = transformPointsInverse(alignmentTransform,caudalXr,caudalYr);
[leftXm,leftYm] = transformPointsInverse(alignmentTransform,leftXr,leftYr);
[rightXm,rightYm] = transformPointsInverse(alignmentTransform,rightXr,rightYr);

if all(xtick([1 end]) <= 0)
    leftText = 'L';
    rightText = 'M';
elseif all(xtick([1 end]) >= 0)
    leftText = 'M';
    rightText = 'L';
else
    leftText = 'S';
    rightText = 'D';
end


for ii = 1:size(map,2)
    figure
    ax1 = axes;
    cax = [min(map(:)) max(map(:))]*mmppxTracking;
    
    imagesc(flipud(reshape(map(:,ii)*mmppxTracking,layout)));
    
    if ~useRealCoords
        saveas(gcf,[finalFolder '_' bodyParts{ii} '_motor_tracking_map'],'fig');
        continue
    end
    
    set(ax1,'XTick',xtick,'XTickLabel',arrayfun(@(f) sprintf('%1.2f',f),xtickMarksBottom,'UniformOutput',false));
    set(ax1,'YTick',ytick,'YTickLabel',arrayfun(@(f) sprintf('%1.2f',f),ytickMarksBottom,'UniformOutput',false));

    ax2 = axes('Color','none','XLim',get(gca,'XLim'),'YLim',get(gca,'YLim'),'XAxisLocation','top','YAxisLocation','right');

    set(ax2,'XTick',xtick,'XTickLabel',arrayfun(@(f) sprintf('%1.2f',f),xtickMarksTop,'UniformOutput',false));
    set(ax2,'YTick',ytick,'YTickLabel',arrayfun(@(f) sprintf('%1.2f',f),ytickMarksTop,'UniformOutput',false));
    
    caxis(ax1,cax);
    c = colorbar(ax1);
    c.Label.String = 'Total movement (mm)';
    
    set(ax2,'Position',get(ax1,'Position'));
    
    xlabel(ax1,'Lateral to Bregma (mm)');
    ylabel(ax1,'Anterior to Bregma (mm)');
    
    line(ax1,verticalLineXm,layout(2)-verticalLineYm,'Color','w','LineWidth',2);
    line(ax1,horizontalLineXm,layout(2)-horizontalLineYm,'Color','w','LineWidth',2);
    patch(ax1,verticalArrowheadsXm,layout(2)-verticalArrowheadsYm,'w','EdgeColor','none');
    patch(ax1,horizontalArrowheadsXm,layout(2)-horizontalArrowheadsYm,'w','EdgeColor','none');
    text(ax1,rostralXm,layout(2)-rostralYm,'R','Color','w','FontSize', 12,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
    text(ax1,caudalXm,layout(2)-caudalYm,'C','Color','w','FontSize',12,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
    text(ax1,leftXm,layout(2)-leftYm,leftText,'Color','w','FontSize',12,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
    text(ax1,rightXm,layout(2)-rightYm,rightText,'Color','w','FontSize',12,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
    
    daspect(ax1,[yscale xscale 1]);
    daspect(ax2,[yscale xscale 1]);
    
    colorbarPosition = get(c,'Position');
    axisPosition = get(ax1,'Position');
    colorbarPadding = colorbarPosition(1) - axisPosition(1) - axisPosition(3);
    
    if colorbarPadding < 0
        colorbarPadding = 0;
    else
        axisPosition(1) = axisPosition(1) - colorbarPadding/2;
        colorbarPadding = colorbarPadding*2;
    end
    
    set(c,'Position',[axisPosition(1) + axisPosition(3) + colorbarPadding colorbarPosition(2:end)]);
    
    set(ax1,'Position',axisPosition); % matlab why do you feel the need to make me do this
    set(ax2,'Position',axisPosition); % matlab why do you feel the need to make me do this
end

%%

for ii = 2 %1:size(map,2)
    figure
    x = ((imrefs{ii}.YWorldLimits(1):(imrefs{ii}.YWorldLimits(2)-1))+0.5-bregmaCoordsPX(2))*mmppxAlignment;
    y = ((imrefs{ii}.XWorldLimits(1):(imrefs{ii}.XWorldLimits(2)-1))+0.5-bregmaCoordsPX(1))*mmppxAlignment;
    c = imrotate(warpedMaps{ii},90);
    a = c ~= 0;
    surf(x,y,zeros(size(c)),c,'AlphaData',a,'CDataMapping','scaled','EdgeColor','none','FaceAlpha','flat','FaceColor','flat');
%     colormap(cmap);
    daspect([1 1 1]);
    set(gca,'YDir','reverse')
    view(2);
    xlabel('Lateral to Bregma (mm)');
    xlim(x([1 end]));
    ylabel('Posterior to Bregma (mm)');
    ylim(y([1 end]));
    
    line(x(1)+[9 7.5; 9 10.5]*diff(x([1 end]))/12,y(1)+[7.5 9; 10.5 9]*diff(y([1 end]))/12,'Color','k','LineWidth',4);
    patch(x(1)+[9 9 7.3 10.7; 8.8 8.8 8 10; 9.2 9.2 8 10]*diff(x([1 end]))/12,y(1)+[7.3 10.7 9 9; 8 10 8.8 8.8; 8 10 9.2 9.2]*diff(y([1 end]))/12,'k');
    
    text(x(1)+9*diff(x([1 end]))/12,y(1)+6.8*diff(y([1 end]))/12,'R','Color','k','FontSize',14,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
    text(x(1)+9*diff(x([1 end]))/12,y(1)+11.2*diff(y([1 end]))/12,'C','Color','k','FontSize',14,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
    text(x(1)+6.8*diff(x([1 end]))/12,y(1)+9*diff(y([1 end]))/12,'M','Color','k','FontSize',14,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
    text(x(1)+11.2*diff(x([1 end]))/12,y(1)+9*diff(y([1 end]))/12,'L','Color','k','FontSize',14,'FontWeight','bold','HorizontalAlignment','center','VerticalAlignment','middle');
end

%% CHOOSE BEST TRIAL AUTOMATICALLY

[~,maxAverageMovement] = max(map(:));
[l,r] = ind2sub(size(map),maxAverageMovement);

[~,t] = max(pathLengths(l,:,r)); %#ok<ASGLU>

%% CHOOSE BEST TRIAL MANUALLY

% map layout for an NxM map:-
%
%       Rostral          N  .  . . . NxM
%          ^             .  .  . . . .
%          |             .  .  . . . .
% Left <---+---> Right   .  .  . . . .
%          |             3 N+3 . . . Nx(M-1)+3
%          v             2 N+2 . . . Nx(M-1)+2
%        Caudal          1 N+1 . . . Nx(M-1)+1

l = 14; % location index (see diagram above)
t = 4; % trial index
r = 2; % ROI index

%% MAKE EXAMPLE TRIAL VIDEO

videoFile = sprintf('VT%d',l-1);
load([videoFile '.mat'],'VT');

% for tt = 1:numel(VT)
w = VideoWriter(sprintf('%s_trial_%d.avi',videoFile,t));
open(w);

for ii = 1:size(VT{t},3)
    tic;
    writeVideo(w,VT{t}(:,:,ii)/255);
    toc;
end

close(w);
% end

%% MAKE EXAMPLE MOTION TRACKING WITH ROI VIDEO

figure
set(gcf,'Position',[100 100 640 512]);
subplot('Position',[0 0 1 1]);

% for tt = 1:numel(VT)
w = VideoWriter(sprintf('%s_trial_%d_with_roi.avi',videoFile,t));
open(w);

for ii = 1:size(VT{t},3)
    tic;
    cla;
    image(VT{t}(:,:,ii));
    colormap(gray(255));
    caxis([0 255]);
    box off;
    set(gca,'XTick',[],'YTick',[]);
    hold on;
    plot(trajectories{l,t}(ii,1,r),trajectories{l,t}(ii,2,r),'LineStyle','none','Marker','o','MarkerEdgeColor','r');
    line(   ...
        roiPositions(r,1)+[0 1 1 0; 1 1 0 0]*roiPositions(r,3)+trajectories{l,t}(ii,1,r)-trajectories{l,t}(1,1,r),   ...
        roiPositions(r,2)+[0 0 1 1; 0 1 1 0]*roiPositions(r,4)+trajectories{l,t}(ii,2,r)-trajectories{l,t}(1,2,r),   ...
    'Color','g');
    writeVideo(w,getframe(gca));
    toc;
end

close(w);

%% MAKE EXAMPLE TRIAL TRAJECTORY OVERLAY VIDEO

figure
set(gcf,'Position',[100 100 640 512]);
subplot('Position',[0 0 1 1]);

%%

% for tt = 1:numel(VT)
w = VideoWriter(sprintf('%s_trial_%d_with_trajectory_overlay.avi',videoFile,t));
open(w);

colours = jet(size(VT{t},3));

h = image(128+VT{t}(:,:,1)/2);
colormap(gray(255));
caxis([0 255]);
box off;
set(gca,'XTick',[],'YTick',[]);
hold on;
for ii = 1:size(map,2)
    plot(trajectories{l,t}(1,1,ii),trajectories{l,t}(1,2,ii),'LineStyle','none','Marker','.','MarkerEdgeColor',colours(1,:));
end
writeVideo(w,getframe(gca));

for ii = 2:size(VT{t},3)
    tic;
    set(h,'CData',128+VT{t}(:,:,ii)/2);
    
    for jj = 1:size(map,2)
        plot(trajectories{l,t}(ii-[1;0],1,jj),trajectories{l,t}(ii-[1;0],2,jj),'Color',colours(ii,:));
    end
    
    writeVideo(w,getframe(gca));
    toc;
end

saveas(gcf,sprintf('%s_trial_%d_with_trajectory_overlay',videoFile,t),'fig');

%% MAKE EXAMPlE TRIAL CLOSE-UP VIDEO

padding = 25;
roiPosition = round(roiPositions(r,:))+[-1 -1 2 2]*padding; % original ROI plus padding pixels of padding on every side
yidx = unique(max(1,min(size(VT{t},1),roiPosition(1)+(0:roiPosition(3)))));
xidx = unique(max(1,min(size(VT{t},1),roiPosition(1)+(0:roiPosition(3)))));

w = VideoWriter(sprintf('%s_trial_%d_%s_cutout.avi',videoFile,t,bodyParts{r}));
open(w);

for ii = 1:size(VT{t},3)
    tic;
    writeVideo(w,VT{t}(yidx,xidx,ii)/255);
    toc;
end

close(w);

%% MAKE EXAMPLE TRIAL MOTION TUBE VIDEO

MT = nan(size(VT{t}));
motionTube = motionTubes{l,t}{r};

for ii = 1:size(MT,3)
    MT( ...
        round(trajectories{l,t}(ii,2,r))+(1:size(motionTube,1))-ceil(size(motionTube,1)/2), ...
        round(trajectories{l,t}(ii,1,r))+(1:size(motionTube,2))-ceil(size(motionTube,2)/2), ...
        ii) = motionTube(:,:,ii);
end

MT = MT(yidx,xidx,:);
MT(isnan(MT)) = 255;

w = VideoWriter(sprintf('%s_trial_%d_%s_motion_tube.avi',videoFile,t,bodyParts{r}));
open(w);

for ii = 1:size(MT,3)
    tic;
    writeVideo(w,MT(:,:,ii)/255);
    toc;
end

close(w);

%% PLOT MOTION TUBE

frameRate = 100; % adjust as appropriate
frameOffset = 11;  % adjust as appropriate
deltaT = 1/frameRate;
tt = ((1:size(motionTube,3))-frameOffset)*deltaT;

figure;
hold on;

for ii = 1:size(MT,3)
    x = trajectories{l,t}(ii,1,r)+(1:size(motionTube,2))-size(motionTube,2)/2-trajectories{l,t}(1,1,r);
    y = trajectories{l,t}(ii,2,r)+(1:size(motionTube,1))-size(motionTube,1)/2-trajectories{l,t}(1,2,r);
    [X,Y] = meshgrid(x,y);
    surf(                                           ...
        tt(ii)*ones(size(X)),                       ...
        X*mmppxTracking,                                    ...
        Y*mmppxTracking,                                    ...
        'CData', motionTube(:,:,ii),                ...
        'CDataMapping', 'scaled',                   ...
        'AlphaData', ~isnan(motionTube(:,:,ii)),    ...
        'AlphaDataMapping', 'none',                 ...
        'EdgeColor', 'none',                        ...
        'FaceColor', 'flat',                        ...
        'FaceAlpha', 'flat'                         ...
        );
end

colormap(gray);
caxis([0 255]);
view(3);
set(gca,'YDir','reverse','ZDir','reverse');
xlabel('Time from Stimulus Onset (s)')
xlim(tt([1 end]));
ylabel('Horizontal Displacement (mm)');
ylim([-3 3]);
zlabel('Vertical Displacement (mm)');
zlim([-3 3]);

saveas(gcf,sprintf('%s_trial_%d_%s_motion_tube',videoFile,t,bodyParts{r}),'fig');
close(gcf);

%% PLOT TRAJECTORIES

colourOrder = distinguishable_colors(size(trajectories,2));

for rr = 1:size(map,2)
    figure;
    hold on;

    for ii = 1:size(trajectories,2)
        x = trajectories{l,ii}(:,1,rr)-trajectories{l,ii}(1,1,rr);
        y = trajectories{l,ii}(:,2,rr)-trajectories{l,ii}(1,2,rr);
        plot3(tt,x*mmppxTracking,y*mmppxTracking,'Color',colourOrder(ii,:),'LineWidth',1+(ii==t));
    end

    view(3);
    set(gca,'YDir','reverse','ZDir','reverse');

    xlabel('Time from Stimulus Onset (s)');
    xlim(tt([1 end]));
    ylabel('Horizontal Displacement (mm)');
    ylim([-2 2]);
    zlabel('Vertical Displacement (mm)');
    zlim([-2 2]);

    saveas(gcf,sprintf('%s_%s_all_trajectories_trial_%d_highlighted',finalFolder,bodyParts{rr},t),'fig');
%     close(gcf);
end

%% PLOT X, Y, AND TOTAL MOVEMENT SEPARATELY

for rr = 1:2
    figure;
    set(gcf,'Position',[969 9 944 988]);

    subplot(3,1,1);

    hold on;

    for ii = 1:size(trajectories,2)
        x = trajectories{l,ii}(:,1,rr)-trajectories{l,ii}(1,1,rr);
        plot(tt,x*mmppxTracking,'Color',colourOrder(ii,:),'LineWidth',1+(ii==t));
    end

    xlabel('Time from Stimulus Onset (s)');
    ylabel('Horizontal Displacement (mm)');

    subplot(3,1,2);

    hold on;

    for ii = 1:size(trajectories,2)
        y = trajectories{l,ii}(:,2,rr)-trajectories{l,ii}(1,2,rr);
        plot(tt,y*mmppxTracking,'Color',colourOrder(ii,:),'LineWidth',1+(ii==t));
    end

    xlabel('Time from Stimulus Onset (s)');
    ylabel('Vertical Displacement (mm)');

    subplot(3,1,3);

    hold on;

    for ii = 1:size(trajectories,2)
        x = trajectories{l,ii}(:,1,rr)-trajectories{l,ii}(1,1,rr);
        y = trajectories{l,ii}(:,2,rr)-trajectories{l,ii}(1,2,rr);
        z = sqrt(x.^2+y.^2);
        plot(tt,z*mmppxTracking,'Color',colourOrder(ii,:),'LineWidth',1+(ii==t));
    end

    xlabel('Time from Stimulus Onset (s)');
    ylabel('Euclidean Distance from Origin (mm)');

    saveas(gcf,sprintf('%s_%s_trajectory_components_trial_%d_highlighted',finalFolder,bodyParts{rr},t),'fig');
    close(gcf);
end