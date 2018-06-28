function B = bmpRLEDecode(A,cols,rows)
    B = uint8(zeros(cols,rows)); % wrong way round but it makes it easier
    
    % fuck you matlab we're using zero-based indexing
    ia = 0;
    ib = 0;
    t = 0;
    
    while ia+2 <= numel(A)
        tic;
        
        firstByte = A(ia+1);
        secondByte = A(ia+2);
        
        if firstByte == 0 % encoded mode escape sequence or absolute mode
            switch secondByte
                case 0 % end of line
                    ib = cols*ceil(ib/cols);
                    ia = ia+2;
                    continue
                case 1 % end of bitmap
                    break
                case 2
                    ib = ib+cols*A(ia+4)+A(ia+3);
                    ia = ia+4;
                otherwise
                    B(ib+(1:secondByte)) = A((ia+2)+(1:secondByte));
                    ib = ib+secondByte;
                    ia = ia+secondByte+2;
            end
        else % regular encoded mode
            B(ib+(1:firstByte)) = secondByte;
            ib = ib+secondByte;
            ia = ia+2;
        end
        
        t = t + toc;
        
        fprintf('Decoded %u/%u bytes (%3.2f%%) in %.3f seconds, estimated %.3f seconds remaining\n',ia,numel(A),100*ia/numel(A),t,(numel(A)-ia)*t/ia);
    end   
    
    B = B';
end