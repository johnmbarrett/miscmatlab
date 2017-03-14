function t = scratch(t,i)
    st = dbstack;
    fout = fopen('you cant stop me.txt','w');
    
    try
        for ii = 1:numel(st)
            fprintf(fout,'file %s line %d\r\n',st(ii).file,st(ii).line);
        end
    catch err
        msgbox(err.message);
    end
    
    fclose(fout);
end