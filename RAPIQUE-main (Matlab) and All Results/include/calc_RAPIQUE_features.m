function feats_frames = calc_RAPIQUE_features(test_video, width, height, ...
                                            framerate, minside, net, layer, log_level)
ti = cputime; 
feats_frames = [];
 
    test_file = fopen(test_video,'r');
    if test_file == -1
        fprintf('Test YUV file not found.');
        feats_frames = [];
        return;
    end
    
    fseek(test_file, 0, 1);
    file_length = ftell(test_file);
    if log_level == 1
        fprintf('Video file size: %d bytes (%d frames)\n',file_length, ...
                floor(file_length/width/height/1.5));
    end
    
    nb_frames = floor(file_length/width/height/1.5);
    
    
    blk_idx = 0;
    for fr = floor(framerate/2):framerate:nb_frames-2
        blk_idx = blk_idx + 1;
        if log_level == 1
        fprintf('Processing %d-th block...\n', blk_idx);
        end
        
        this_YUV_frame = YUVread(test_file,[width height],fr);

        

        prev_YUV_frame = YUVread(test_file,[width height],max(1,fr-floor(framerate/3)));
        next_YUV_frame = YUVread(test_file,[width height],min(nb_frames-2,fr+floor(framerate/3)));
        
        this_rgb = reshape(convertYuvToRgb(reshape(this_YUV_frame, width * height, 3)), ...
                          height, width, 3);
        prev_rgb = reshape(convertYuvToRgb(reshape(prev_YUV_frame, width * height, 3)), ...
                          height, width, 3);
        next_rgb = reshape(convertYuvToRgb(reshape(next_YUV_frame, width * height, 3)), ...
                          height, width, 3);

        
        sside = min(size(this_YUV_frame,1), size(this_YUV_frame,2));
        ratio = minside / sside;
        if ratio < 1
            prev_rgb = imresize(prev_rgb, ratio);
            next_rgb = imresize(next_rgb, ratio);
        end
        
        feats_per_frame = [];
        
        
        prev_feats_spt = RAPIQUE_spatial_features(prev_rgb);
        

        next_feats_spt = RAPIQUE_spatial_features(next_rgb);
        
        
        %% mean and variation pooling of spatial features within chunk
        feats_spt_mean = mean([prev_feats_spt; next_feats_spt], 'omitnan');
        feats_spt_diff = abs(prev_feats_spt - next_feats_spt);
        feats_per_frame = [feats_per_frame, feats_spt_mean, feats_spt_diff];
        
        
        %% extract deep learning features
        temp_time = cputime;
        if log_level == 1
        fprintf('- Extracting CNN features (1 fps) ...')
        end
        input_size = net.Layers(1).InputSize;
        im_scale = imresize(this_rgb, [input_size(1), input_size(2)]);
        
        feats_spt_deep = activations(net, im_scale, layer, ...
                            'ExecutionEnvironment','cpu');
        dl_feats_time = cputime -temp_time;
        upd_FuncInfo("calc_RAPIQUE_features/deep_learning",dl_feats_time);
        feats_per_frame = [feats_per_frame, squeeze(feats_spt_deep)'];
        
        %% extract temporal NSS features - 476-dim
        temp_time = cputime;
        if log_level == 1
        fprintf('- Extracting temporal NSS features (8 fps) ...')
        tic
        end
        wfun = load(fullfile('include', 'WPT_Filters', 'haar_wpt_3.mat'));
        wfun = wfun.wfun;
        frames_wpt = zeros(size(prev_rgb, 1), size(prev_rgb, 2), size(wfun, 2));
        fr_idx_start = max(1, fr - floor(size(wfun, 2) / 2));
        fr_idx_end = min(nb_frames - 3, fr_idx_start + size(wfun, 2) - 1);
        fr_wpt_cnt = 1;
        for fr_wpt = fr_idx_start:fr_idx_end
            YUV_tmp = YUVread(test_file, [width height], fr_wpt);
            if ratio < 1
                frames_wpt(:,:,fr_wpt_cnt) = imresize(YUV_tmp(:,:,1), ratio);
            else
                frames_wpt(:,:,fr_wpt_cnt) = YUV_tmp(:,:,1);
            end
            fr_wpt_cnt = fr_wpt_cnt + 1;
        end
        dpt_filt_frames = zeros(size(prev_rgb, 1), size(prev_rgb, 2), size(wfun, 1));
        
        for freq = 1:size(wfun, 1)
            dpt_filt_frames(:,:,freq) = sum(frames_wpt .* ...
                reshape(wfun(freq,:),1,1,[]), 3);
        end
        kscale = 2; 
        feats_tmp_wpt = [];
        for ch = 1:size(dpt_filt_frames, 3)
            if ratio < 1
                feat_map = imresize(dpt_filt_frames(:,:,ch), ratio);
            else
                feat_map = dpt_filt_frames(:,:,ch);
            end
            for scale = 1:kscale
                y_scale = imresize(feat_map, 2 ^ (-(scale - 1)));
                feats_tmp_wpt = [feats_tmp_wpt, rapique_basic_extractor(y_scale)];
            end
        end
        tNSS_time = cputime -temp_time;
        upd_FuncInfo("calc_RAPIQUE_features/temporal NSS",tNSS_time);

        if log_level == 1, toc; end
        feats_per_frame = [feats_per_frame, feats_tmp_wpt];
        feats_frames(end+1,:) = feats_per_frame;
    end
    % Leer el archivo XML
 %xmlData = xmlread('feat_frames.xml');

% Extraer el contenido de texto dentro del nodo <data>
 %dataNode = xmlData.getElementsByTagName('data').item(0);
 %dataStr = char(dataNode.getFirstChild.getData);

% Convertir la cadena de texto a números
 %dataNum = str2double(strsplit(strtrim(dataStr)));

% Cambiar la forma de los datos a 8x3884
 %dataMat = reshape(dataNum, [3884, 8])'; % Asegúrate de que los datos sean correctos antes de hacer el reshape
 %numRows = size(dataMat, 1); % Número de filas
 %correlationCoefficients = zeros(numRows, 1); % Almacenar coeficientes de correlación

 %for i = 1:numRows
     %R = corrcoef(dataMat(i, :), feats_frames(i, :));
     %correlationCoefficients(i) = R(1, 2); % Coeficiente de correlación entre las filas correspondientes
 %end
    fclose(test_file);

    % Detener el contador de tiempo
    elapsed_time = cputime - ti;
    upd_FuncInfo("calc_RAPIQUE_features",elapsed_time);

end

% Read one frame from YUV file
function YUV = YUVread(f, dim, frnum)

    
    
    fseek(f, dim(1)*dim(2)*1.5*frnum, 'bof');
    
   
    Y = fread(f, dim(1)*dim(2), 'uchar');
    if length(Y) < dim(1)*dim(2)
        YUV = [];
        return;
    end
    Y = cast(reshape(Y, dim(1), dim(2)), 'double');
    
 
    U = fread(f, dim(1)*dim(2)/4, 'uchar');
    if length(U) < dim(1)*dim(2)/4
        YUV = [];
        return;
    end
    U = cast(reshape(U, dim(1)/2, dim(2)/2), 'double');
    U = imresize(U, 2.0);
    
    
    V = fread(f, dim(1)*dim(2)/4, 'uchar');
    if length(V) < dim(1)*dim(2)/4
        YUV = [];
        return;
    end    
    V = cast(reshape(V, dim(1)/2, dim(2)/2), 'double');
    V = imresize(V, 2.0);
    
    YUV(:,:,1) = Y';
    YUV(:,:,2) = U';
    YUV(:,:,3) = V';


end