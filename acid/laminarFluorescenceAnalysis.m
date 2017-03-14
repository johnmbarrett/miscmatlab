function [mask,theta] = laminarFluorescenceAnalysis(file,mask,theta)
    I = double(TIFFStack([file '.tif']));
    J = medianBin(I,8,8);
    K = artifactSubtraction(J,[1:83:1245;83:83:1245]',9:17,repmat([false;true;true],5,1),repmat([false;false;true],5,1),file);
    
    if nargin < 2
        [mask,theta] = chooseRotatedRectangleROI(mean(mean(K,4),3));
    end
    
    Ks = squeeze(mat2cell(K,75,100,83,ones(10,1)));
    [H,dFF0,figs] = makeLaminarFlourescenceChangeProfile(Ks,mask,theta,true(83,1),[1:83:830;8:83:830]',[1:83:830;83:83:830]',[zeros(10,1) repmat([0;1],5,1)],[file '_laminar_profile']); %#ok<ASGLU>
    save([file '.mat'],'H','dFF0','-append');
    saveas(figs,[file '_laminar_profile'],'fig');
    makeMeanDeltaFF0Video(dFF0,[ones(10,1) repmat([0;1],5,1)],[file 'dff0'],{'Dummy' 'Stim On'},1000/120,@(x,y) [0.025+0.5*(x-1) 0.05 0.45 0.9],[0 0 1587 996]);
end