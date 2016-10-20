function qcamrawToTIFF(qcamFiles)
    % TODO : uigetfiles
    if ischar(qcamFiles)
        qcamFiles = {qcamFiles};
    elseif ~iscell(qcamFiles)
        error('Input must be a string or a cell array of strings');
    end
    
    for ii = 1:numel(qcamFiles)
        qcamFile = qcamFiles{ii};
        
        if ~exist(qcamFile,'file')
            warning('File %s does not exist, ignoring...\n',qcamFile);
            continue
        end
            
        fin = fopen(qcamFiles{ii},'rb');
        
        qcamHeader = parseQCamHeader(fin);
        
        [~,filename] = fileparts(qcamFile);
        
        tiffFile = Tiff([filename '.tif'],'w');
        
        fseek(fin,0,1);
        
        nFrames = (ftell(fin)-qcamHeader.FixedHeaderSize)/qcamHeader.FrameSize;
        
        fseek(fin,qcamHeader.FixedHeaderSize,-1);
        
        height = qcamHeader.ROI(4)-qcamHeader.ROI(2);
        width = qcamHeader.ROI(3)-qcamHeader.ROI(1);
        
        for jj = 1:nFrames
            tic;
            frame = fread(fin,[width height],'uint16=>uint16')'; % TODO : precision from header
            
            tiffFile.setTag('Photometric',Tiff.Photometric.MinIsBlack); % TODO : read from header
            tiffFile.setTag('BitsPerSample',qcamHeader.BytesPerPixel*8);
            tiffFile.setTag('Compression',Tiff.Compression.LZW); % TODO : expose param
            tiffFile.setTag('ImageLength',height);
            tiffFile.setTag('ImageWidth',width);
            tiffFile.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky); % TODO : right?
            tiffFile.setTag('RowsPerStrip',16); % TODO : ??? also expose as param
            tiffFile.setTag('SampleFormat',Tiff.SampleFormat.UInt); % TODO : read from header
            tiffFile.setTag('SamplesPerPixel',1); % TODO : read from header
        
            tiffFile.write(frame);
            tiffFile.writeDirectory();
            toc;
        end
        
        tiffFile.close();
    end
end