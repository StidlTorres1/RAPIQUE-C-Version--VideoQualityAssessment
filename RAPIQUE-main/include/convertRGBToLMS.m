%{
Author: Deepti Ghadiyaram

Description: Given an input RGB image, this method transforms the input
into LMS color space.
%}

function lms= convertRGBToLMS(rgb)

ti = cputime;

    lms = (colorspace('RGB->CAT02 LMS',rgb));

% Detener el contador de tiempo
elapsed_time = cputime - ti;
upd_FuncInfo("convertRGBToLMS",elapsed_time);

end
