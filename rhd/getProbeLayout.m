function layout = getProbeLayout(nProbes,version)
% adapted from Xiaojian's LNSN_1
% are hard coded variables really the best way to do this?!

    layouts = cell(32,3);
    layouts{32,1} = [1;17;16;32;3;19;14;30;9;25;10;20;8;24;2;29;7;26;15;21;11;23;12;28;6;18;13;22;5;27;4;31];
    layouts{32,2} = [29;26;24;21;20;23;25;28;30;18;19;22;32;27;17;31;7;2;15;8;11;10;12;9;6;14;13;3;5;16;5;1];
    layouts{32,3} = [4;5;13;6;12;11;15;7;2;8;10;9;14;3;16;1;17;32;19;30;25;20;24;29;26;21;23;28;18;22;27;31];
    layouts{16,1} = [9 8 10 7 13 4 12 5 15 2 16 1 14 3 11 6]';
    layouts{16,2} = [16 2 14 4 9 7 10 8 13 3 15 1 11 5 12 6]';
    layouts{16,3} = [5 13 4 12 7 15 3 11 8 16 1 9 2 10 6 14]';    

    layout = layouts{nProbes,version};
    
    if isempty(layout)
        error('Unsupported probe configuration %d.%d\n',nProbes,version);
    end
end
