topFolder = 'Z:\LACIE\DATA\John\Videos\Behaviour';
day = '20180219';
cage = 'K156582';
mouse = 'ted';

%%

cd(sprintf('%s\\%s\\%s',topFolder,day,cage));

%%

matFile = dir(sprintf('%s_session_1*.mat',mouse));

if isempty(matFile)
    error('Try picking a mouse that actually exists.');
end

load(matFile(1).name);

%%

if ~exist('successIndices','var') || isempty(successIndices)
    error('Try picking a less stupid mouse.');
end

exampleTime = -0.249:0.001:0.25;
exampleAngles = nan(numel(exampleTime),numel(successIndices));

for ii = 1:size(exampleAngles,2)
    ts = exampleTime+successTimes(ii);
    
    bad = false(size(ts));
    
    if ii > 1
        bad = bad | ts <= successTimes(ii-1);
        offset = angle(successIndices(ii-1));
    else
        offset = 0;
    end
    
    if ii < numel(successIndices);
        bad = bad | ts >= successTimes(ii+1);
    end
    
    exampleAngles(~bad,ii) = interp1(timestamps,angle-offset,ts(~bad),'pchip');
end

%%

figure
plot(exampleTime,exampleAngles(:,1),'Color','b');
line(repmat(xlim',1,2),threshold(successIndices(1))*[-1 1; -1 1],'Color','r');
line([0 0],ylim,'Color','k','LineStyle','--');
xlabel('Time from threshold crossing (s)');
ylabel('Angle (degrees)');
legend({'Wheel' 'Threshold'});

%%

exampleAngles = zeros(numel(exampleAngle),numel(successIndices));