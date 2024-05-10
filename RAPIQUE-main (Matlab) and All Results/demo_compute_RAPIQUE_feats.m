%%
% Compute features for a set of video files from datasets
% 


delete function_stats.csv; %delete csv with functions execution stats
%tStart = tic;
ttotal_i = cputime;
% add path
addpath(genpath('include'));

%%
% parameters
algo_name = 'RAPIQUE'; % algorithm name, eg, 'V-BLIINDS'
data_name = 'all_combined';  % dataset name, eg, 'KONVID_1K'
write_file = true;  % if true, save features on-the-fly
log_level = 0;  % 1=verbose, 0=quite

if strcmp(data_name, 'KONVID_1K')
    root_path = 'C:\Users\stidl\Desktop\root\';
    data_path = 'X:\RAPIQUE_proyecto\RAPIQUE-project\KoNViD_1k_videos\KoNViD_1k_videos';
elseif strcmp(data_name, 'LIVE_VQC')
    root_path = '/media/ztu/Seagate-ztu-ugc/LIVE_VQC/';
    data_path = 'X:\RAPIQUE_proyecto\RAPIQUE-project\LIVE_VQC_videos\Video';
elseif strcmp(data_name, 'YOUTUBE_UGC')
    root_path = '/media/ztu/Seagate-ztu-ugc/YT_UGC';
    data_path = 'X:\RAPIQUE_proyecto\RAPIQUE-project\YOUTUBE_UGC_videos';
elseif strcmp(data_name, 'LIVE_HFR')
    root_path = '/media/ztu/Seagate-ztu/LIVE_HFR';
    data_path = '/media/ztu/Seagate-ztu/LIVE_HFR';
elseif strcmp(data_name, 'LIVE_VQA')
    root_path = '/media/ztu/Seagate-ztu/LIVE_VQA';
    data_path = '/media/ztu/Seagate-ztu/LIVE_VQA/videos';
elseif strcmp(data_name, 'LIVE_Qualcomm')
    root_path = '/media/ztu/Seagate-ztu/LIVE_VQA';
    data_path = 'X:\RAPIQUE_proyecto\RAPIQUE-project\live_Qualcomm_videos';
elseif strcmp(data_name, 'CVD_2014')
    root_path = '/media/ztu/Seagate-ztu/LIVE_VQA';
    data_path = 'X:\RAPIQUE_proyecto\RAPIQUE-project\CVD2014_videos';
elseif strcmp(data_name, 'all_combined')
    root_path = '/media/ztu/Seagate-ztu/LIVE_VQA';
    data_path = 'X:\RAPIQUE_proyecto\RAPIQUE-project\RAPIQUE-VideoQualityAssessment\dataBase\databaseall\videos';
end

%%
% create temp dir to store decoded videos
video_tmp = 'X:\AppData\Local\tmp';
if ~exist(video_tmp, 'dir'), mkdir(video_tmp); end
feat_path = 'mos_files';
%filelist_csv = fullfile(feat_path, [data_name,'_metadata.csv']);
filelist_csv = fullfile(feat_path, [data_name,'_metadata.csv']);
filelist = readtable(filelist_csv);
num_videos = size(filelist,1);
out_path = 'feat_files';
if ~exist(out_path, 'dir'), mkdir(out_path); end
out_mat_name = fullfile(out_path, [data_name,'_',algo_name,'_feats.mat']);
feats_mat = [];
feats_mat_frames = cell(num_videos, 1);
%===================================================

% init deep learning models
minside = 512.0;
net = resnet50;
layer = 'avg_pool';

%% extract features
func_info = zeros(15,2); %init matrix to storage functions execution stats
% parfor i = 1:num_vieos % for parallel speedup
for i = 1:num_videos
    video_shortname_cell = table2cell(filelist(i, 1));
    video_shortname = video_shortname_cell{1}; %update video_shortname for func_info
    save('func_info.mat',"func_info","video_shortname"); %save flickrid & matrix in .mat file
    progressbar(i/num_videos) % Update figure
    if strcmp(data_name, 'KONVID_1K')
        video_name = fullfile(data_path, ...
            [num2str(filelist.flickr_id(i)),'.mp4']);
        yuv_name = fullfile(video_tmp, [num2str(filelist.flickr_id(i)), '.yuv']);
    elseif strcmp(data_name, 'LIVE_VQC')
        video_name = fullfile(data_path, filelist.File{i});
        yuv_name = fullfile(video_tmp, [filelist.File{i}, '.yuv']);
    elseif strcmp(data_name, 'YOUTUBE_UGC')
        video_name = fullfile(data_path, [char(filelist.vid_name(i)) '_crf_10_ss_00_t_20.0.mp4']);
%, ...
            %[num2str(filelist.resolution(i)),'P'],[filelist.vid{i},'.mkv']);
        yuv_name = fullfile(video_tmp, [char(filelist.vid_name(i)), '.yuv']);
    elseif strcmp(data_name, 'LIVE_HFR')
        strs = strsplit(filelist.Filename{i}, '_');
        video_name = fullfile(data_path,strs{1},[filelist.Filename{i},'.webm']);
        yuv_name = fullfile(video_tmp, [filelist.Filename{i}, '.yuv']);
    elseif strcmp(data_name, 'LIVE_VQA')
        strs = strsplit(filelist.filename{i}, '_');
        video_name = fullfile(data_path, [strs{1}(1:2), '_Folder'], filelist.filename{i});
        yuv_name = video_name;
    elseif strcmp(data_name, 'LIVE_Qualcomm')
        %strs = strsplit(filelist.filename{i}, '_');
        video_name = fullfile(data_path, filelist.Filename{i});
        yuv_name = video_name;
    elseif strcmp(data_name, 'CVD_2014')
        %strs = strsplit(filelist.filename{i}, '_');
        video_name = fullfile(data_path, filelist.nombre{i});
        [~, nombreSinExtension, ~] = fileparts(filelist.nombre{i});
        yuv_name = fullfile(video_tmp, [nombreSinExtension, '.yuv']);
    elseif strcmp(data_name, 'all_combined')
        video_name = fullfile(data_path, ...
            filelist.flickr_id{i});
        [~, nombreSinExtension, ~] = fileparts(filelist.flickr_id{i});
        yuv_name = fullfile(video_tmp, [nombreSinExtension, '.yuv']);
    end
    
    fprintf('\n\nComputing features for %d sequence: %s\n', i, video_name);

    % decode video and store in temp dir
    if ~strcmp(video_name, yuv_name)  %verificar si ya esta en yuv para saltarse esta linea
        cmd = ['ffmpeg -loglevel error -y -i ', video_name, ...
            ' -pix_fmt yuv420p -vsync 0 ', yuv_name];
        system(cmd);
    end

    % get video meta data
    width = filelist.width(i);
    height = filelist.height(i);
    framerate = round(filelist.framerate(i));

    % calculate video featuress
    tStart = tic;
    feats_frames = calc_RAPIQUE_features(yuv_name, width, height, ...
        framerate, minside, net, layer, log_level);
    fprintf('\nOverall %f seconds elapsed...', toc(tStart));
    % 
    feats_mat(i,:) = mean(feats_frames, 'omitnan');
    feats_mat_frames{i} = feats_frames;
    % clear cache
    delete(yuv_name)

    if write_file
        save(out_mat_name, 'feats_mat');
%         save(out_mat_name, 'feats_mat', 'feats_mat_frames');
    end

    upd_FuncInfo('next'); %restore matrix to zeros. %save csv
end
ttotal = cputime-ttotal_i
fid = fopen('function_stats.csv', 'a');
fprintf(fid, '"%s","%s",%d,%f\n', 'RAPIQUE-Main', 'demo_compute_RAPIQUE_feats', 1, ttotal);
fclose(fid);

