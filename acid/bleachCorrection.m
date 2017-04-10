function bleachCorrection(file)
    if nargin < 1
        [~,file] = fileparts(pwd);
        file = [file '_dff0.mat'];
    end
    
    load(file);
    
    sizeD = size(dff0); %#ok<NODEF>
    
    x = repmat((0.1:0.1:sizeD(3)/10)',sizeD(4),1);
    y = squeeze(nanmedian(reshape(dff0,[prod(sizeD(1:2)) sizeD(3:4)])));
    
    f = fit(x,y(:),'poly2');
    
    figure;
    plot(f,x,y);
    
    X = reshape(x,[1 1 sizeD(3:4)]);
    ff = @(x) f.p1*x.^2 + f.p2*x + f.p3;
    
    dff0 = bsxfun(@minus,dff0,ff(X));
    
    figure;
    plot(f,x,dff0(:));
    
    save(strrep(file,'_dff0','_bleach_corrected_dff0'),'f0','dff0','x','y','f','ff');
    makeMeanDeltaFF0Video(dff0,[ones(sizeD(4),1) repmat([0;1],sizeD(4)/2,1)],strrep(file,'_dff0.mat','_bleach_corrected_basic.avi'),{'Dummy' 'Stim On'},(sizeD(3)+1)/10,@(x,y) [0.025+0.5*(x-1) 0.05 0.45 0.9],[0 0 900 300]);
end