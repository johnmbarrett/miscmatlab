function vnew = validateAndApplyNumericTextEntry(box,slider,validateFun)
    s = get(box,'String');

    sign = 1;

    if s(1) == '-'
        sign = -1;
        s = s(2:end);
    end

    s = s(ismember(s,'.0123456789'));

    if isempty(s)
        s = '';
    end

    vold = sign*str2double(s);
    
    isThereASlider = nargin > 1 && isscalar(slider) && isgraphics(slider); % TODO : check it's actually a slider
    
    if isThereASlider
        vnew = min(get(slider,'Max'),max(get(slider,'Min'),vold));
    else
        vnew = vold;
    end
    
    if nargin > 2 && isa(validateFun,'function_handle')
        vnew = validateFun(vnew);
    end

    if vold ~= vnew
        s = num2str(vnew);
    end

    if sign == -1
        s = ['-' s];
    end

    set(box,'String',s);
    
    if isThereASlider
        set(slider,'Value',vnew);
    end
end