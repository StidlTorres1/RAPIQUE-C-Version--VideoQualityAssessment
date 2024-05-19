    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute features for a set of video files from LIVE-Qualcomm databse
%
tic;  % Start timing the entire script
t1 = cputime;
% Read subjective data
data = load('all_combined_metadata.mat');
frates = 30;
reso = [1920 1080];

% Open feature file for output
feature_file = '.\nr-vqa_features.csv'; 
fid_ftr = fopen(feature_file,'w+');

% Loop through all the video files in the database
for z=180:length(data.all_combined.flickr_id)

    yuv_path = 'X:\RAPIQUE_proyecto\RAPIQUE-project\RAPIQUE-VideoQualityAssessment\dataBase\databaseall\all_combined\';
    full_yuv_path = sprintf('%s/%s', yuv_path, ...
                            data.all_combined.flickr_id{z});
    yuv_name = strrep(data.all_combined.flickr_id{z}, '.mp4', '.yuv');
    real_full_yuv_path = sprintf('%s%s%s', yuv_path, ...
                            'tmp\',yuv_name);
    cmd = ['ffmpeg -loglevel error -y -i ', full_yuv_path, ...
            ' -pix_fmt yuv420p -vsync 0 ', real_full_yuv_path];
    system(cmd);

    resox = data.all_combined.width(z);
    resoy = data.all_combined.height(z);
    reso = [resox,resoy];
    frates = round(data.all_combined.framerate(z));

    % Compute features for each video file
    fprintf('Computing features for sequence: %s\n',real_full_yuv_path)
    tic
    tstart = cputime;
    features = compute_nrvqa_features(real_full_yuv_path, reso, frates);
    tend = cputime -tstart 
    toc
    
    % Write features to csv file for further processing
    fprintf(fid_ftr, '%2.2f, %2.2f,%0.2f,%0.2f', ...
            data.all_combined.mos(z), ...
            data.all_combined.mos(z), reso(1)/1920, 1);
    for j=1:length(features)
        fprintf(fid_ftr, ',%0.5f', features(j));
    end
    fprintf(fid_ftr, '\n');
  
end
fclose(fid_ftr);
fprintf('All done!\n');

total = cputime - t1
toc;
