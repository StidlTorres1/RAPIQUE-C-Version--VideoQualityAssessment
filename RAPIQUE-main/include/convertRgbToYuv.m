function yuv = convertRgbToYuv(rgb)
% convert row vector RGB [0, 255] to row vector YUV [0, 255]
ti = cputime;

load conversion.mat;

rgb = double(rgb);

yuv = (rgbToYuv * rgb.').';
yuv(:, 2 : 3) = yuv(:, 2 : 3) + 127;

yuv = uint8(clipValue(yuv, 0, 255));

% Detener el contador de tiempo
elapsed_time = cputime - ti;
upd_FuncInfo("convertRgbToYuv",elapsed_time);