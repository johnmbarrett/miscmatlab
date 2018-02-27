function y = sigmf(x,p)
% this is really fucking basic but for some reason you need to buy the
% fuzzy logic toolbox to use it?  fuck you matlab
    y = 1./(1+exp(-p(1).*(x-p(2))));
end