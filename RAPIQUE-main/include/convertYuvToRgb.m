function rgb = convertYuvToRgb(yuv)
% convert row vector YUV [0, 255] in row vector RGB [0, 255]
ti = cputime;

load conversion.mat; % load conversion matrices

yuv = double(yuv);

yuv(:, 2 : 3) = yuv(:, 2 : 3) - 127;
rgb = (yuvToRgb *yuv.').';

rgb = uint8(clipValue(rgb, 0, 255));

% Detener el contador de tiempo
elapsed_time = cputime - ti;
upd_FuncInfo("convertYuvToRgb",elapsed_time);