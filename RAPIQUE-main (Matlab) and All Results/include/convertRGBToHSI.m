%{
Author: Deepti Ghadiyaram

Description: Given an input RGB image, this method transforms the input
into HSI color space.
%}

function hsi= convertRGBToHSI(rgb)

ti = cputime;
    hsi = (colorspace('RGB->HSI',rgb));

% Detener el contador de tiempo
elapsed_time = cputime - ti;
upd_FuncInfo("convertRGBToHSI",elapsed_time);
    
end

