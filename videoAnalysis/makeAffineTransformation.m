function tf = makeAffineTransformation(xoff,yoff,scaleFactor,theta)
    trans = [1 0 0; 0 1 0; xoff yoff 1];
    scale = [scaleFactor 0 0; 0 scaleFactor 0; 0 0 1];
    rot = [cos(theta) -sin(theta) 0; sin(theta) cos(theta) 0; 0 0 1];
    
    tf = affine2d(rot*scale*trans);
end