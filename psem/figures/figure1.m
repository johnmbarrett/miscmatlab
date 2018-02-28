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

firstSuccessIndex = successIndices(1);
firstSuccessTime = timestamps(firstSuccessIndex);
exampleTime = -0.499:0.001:0.5;
exampleAngle = interp1(timestamps,angle,exampleTime+firstSuccessTime,'pchip');

%%

figure
plot(exampleTime,exampleAngle,'Color','b');
line(repmat(xlim',1,2),threshold(firstSuccessIndex)*[-1 1; -1 1],'Color','r');
line([0 0],ylim,'Color','k','LineStyle','--');
xlabel('Time from threshold crossing (s)');
ylabel('Angle (degrees)');
legend({'Wheel' 'Threshold'});

%%

