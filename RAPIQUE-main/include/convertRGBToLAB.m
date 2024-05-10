%{
Author: Deepti Ghadiyaram

Description: Given an input RGB image, this method transforms the input
into LAB color space.
%}

function lab = convertRGBToLAB(I)

ti = cputime;

    gfrgb = imfilter(I, fspecial('gaussian', 3, 3), 'symmetric', 'conv');
    cform = makecform('srgb2lab', 'AdaptedWhitePoint', whitepoint('D65'));

    lab = applycform(gfrgb,cform);

% Detener el contador de tiempo
elapsed_time = cputime - ti;
upd_FuncInfo("convertRGBToLAB",elapsed_time);
end