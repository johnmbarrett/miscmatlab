function validateAndApplyNumericTextEntry(box,slider)
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
    vnew = min(get(slider,'Max'),max(get(slider,'Min'),vold));

    if vold ~= vnew
        s = num2str(vnew);
    end

    if sign == -1
        s = ['-' s];
    end

    set(box,'String',s);
    set(slider,'Value',vnew);
end