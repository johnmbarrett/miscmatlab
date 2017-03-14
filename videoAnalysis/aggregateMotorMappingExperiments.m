load('motor_mapping.mat');

%% TODO : code to construct frontMovement and leftMovement

%%

simpleMaps12x12 = find(cellfun(@(A) isequal(A,[12 12]),T.layout));
nSimpleMaps = numel(simpleMaps12x12)/2;

motionTrackings = {zeros(12,12,2,nSimpleMaps) zeros(12,12,3,nSimpleMaps)};

for ii = 1:nSimpleMaps
    for jj = 1:2
        idx = simpleMaps12x12(2*(ii-1)+jj);
        cd(T.path{idx});
        load(sprintf('%s_motion_tracking.mat',T.view{idx}));
        motionTrackings{jj}(:,:,:,ii) = reshape(map,[12 12 size(map,2)]);
    end
end

save('motor_mapping.mat','-append','motionTrackings');

%%

datas = [{frontMovement leftMovement}; motionTrackings];
prefixes = {'front_movement' 'left_movement'};
bodyParts = {{'Right Paw' 'Left Paw'} {'Forepaws' 'Left Hindpaw' 'Tail'}; {'Right Paw' 'Left Paw'} {'Right Forepaw' 'Left Forepaw' 'Left Hindpaw'}};
analyses = {'zscore' 'motion_tracking'};

figure;
for hh = 1:2
    for ii = 1:2
        clf;
        nBodyParts = size(datas{hh,ii},3);

        maxMovement = reshape(max(reshape(datas{hh,ii},[144 nBodyParts 6])),[1 1 nBodyParts 6]);
        minMovement = reshape(min(reshape(datas{hh,ii},[144 nBodyParts 6])),[1 1 nBodyParts 6]);
        normMovement = bsxfun(@rdivide,bsxfun(@minus,datas{hh,ii},minMovement),maxMovement-minMovement);

        colourMovement = zeros(12,12,3);

        for jj = 1:nBodyParts
            meanMovement = mean(normMovement(:,:,jj,:),4);

            imagesc(flipud(meanMovement));
            saveas(gcf,sprintf('%s_%s_average_%s_map',prefixes{ii},strrep(lower(bodyParts{ii}{jj}),' ','_'),analyses{hh}),'fig');

            colourMovement(:,:,jj) = meanMovement;
        end

        clf;
        hold on;
        hs = zeros(1,3);

        for jj = 1:nBodyParts
            colour = zeros(1,3);
            colour(jj) = 1;

            hs(jj) = fill([-1 -2 -2 -1],[-1 -1 -2 -2],colour,'EdgeColor',[0 0 0]);
        end

        imagesc(colourMovement);
        xlim([0.5 12.5]);
        ylim([0.5 12.5]);
        legend(hs(1:nBodyParts),bodyParts{ii}(1:nBodyParts),'Location','NorthWest');
        saveas(gcf,sprintf('%s_composite_%s_map',prefixes{ii},analyses{hh}),'fig');
    end
end