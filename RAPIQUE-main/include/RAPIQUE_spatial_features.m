function feats = RAPIQUE_spatial_features(RGB)
 ti = cputime;

    feats = [];
    
    if(size(RGB,3) ~=3)
        error('The input should be an RGB image');
    end
    kscale = 2;
    kband = 4; 
    
   
    sigmaForGauDerivative = 1.66;
    scaleFactorForGaussianDer = 0.28;
    Y = double(rgb2gray(RGB));
    
    
    [GM, ~] = imgradient(Y);
    
    window2 = fspecial('log', 9, 9/6);
    window2 =  window2/sum(abs(window2(:)));
    LOG = abs(imfilter(Y, window2, 'replicate'));
       
    [~, DOG] = gen_DoG(Y, kband);
    
   
    RGB = double(RGB);
    O1 = 0.30*RGB(:,:,1) + 0.04*RGB(:,:,2) - 0.35*RGB(:,:,3);
    O2 = 0.34*RGB(:,:,1) - 0.60*RGB(:,:,2) + 0.17*RGB(:,:,3);

    [dx, dy] = gauDerivative(sigmaForGauDerivative/(1^scaleFactorForGaussianDer));
    compRes = conv2(O1, dx + 1i*dy, 'same');
    IxO1 = real(compRes);
    IyO1 = imag(compRes);
    GMO1 = sqrt(IxO1.^2 + IyO1.^2) + eps;
        
    compRes = conv2(O2, dx + 1i*dy, 'same');
    IxO2 = real(compRes);
    IyO2 = imag(compRes);
    GMO2 = sqrt(IxO2.^2 + IyO2.^2) + eps;
    
    logR = log(RGB(:,:,1) + 0.1);
    logG = log(RGB(:,:,2) + 0.1);
    logB = log(RGB(:,:,3) + 0.1);
    logRMS = logR - mean2(logR);
    logGMS = logG - mean2(logG);
    logBMS = logB - mean2(logB);
    
  
    BY = (logRMS + logGMS - 2 * logBMS) / sqrt(6);
    RG = (logRMS - logGMS) / sqrt(2);
    
    [dx, dy] = gauDerivative(sigmaForGauDerivative/(1^scaleFactorForGaussianDer));
    compRes = conv2(BY, dx + 1i*dy, 'same');
    IxBY = real(compRes);
    IyBY = imag(compRes);
    GMBY = sqrt(IxBY.^2 + IyBY.^2) + eps;
    
    [dx, dy] = gauDerivative(sigmaForGauDerivative/(1^scaleFactorForGaussianDer));
    compRes = conv2(RG, dx + 1i*dy, 'same');
    IxRG = real(compRes);
    IyRG = imag(compRes);
    GMRG = sqrt(IxRG.^2 + IyRG.^2) + eps;

    
    LAB = convertRGBToLAB(uint8(RGB));
    LAB = double(LAB);
    
    A = double(LAB(:,:,2));
    B = double(LAB(:,:,3));

    [dx, dy] = gauDerivative(sigmaForGauDerivative/(1^scaleFactorForGaussianDer));
    compRes = conv2(A, dx + 1i*dy, 'same');
    IxA = real(compRes);
    IyA = imag(compRes);
    GMA = sqrt(IxA.^2 + IyA.^2) + eps;
    
    [dx, dy] = gauDerivative(sigmaForGauDerivative/(1^scaleFactorForGaussianDer));
    compRes = conv2(B, dx + 1i*dy, 'same');
    IxB = real(compRes);
    IyB = imag(compRes);
    GMB = sqrt(IxB.^2 + IyB.^2) + eps;
    
    
    compositeMat = [];
    compositeMat = cat(3, compositeMat, Y);
    compositeMat = cat(3, compositeMat, GM);
    compositeMat = cat(3, compositeMat, LOG);
    compositeMat = cat(3, compositeMat, DOG(:,:,1));

    
    
    compositeMat = cat(3, compositeMat, O1);
    compositeMat = cat(3, compositeMat, O2);
    compositeMat = cat(3, compositeMat, GMO1);
    compositeMat = cat(3, compositeMat, GMO2);
    compositeMat = cat(3, compositeMat, BY);
    compositeMat = cat(3, compositeMat, RG);
    compositeMat = cat(3, compositeMat, GMBY);
    compositeMat = cat(3, compositeMat, GMRG);
    compositeMat = cat(3, compositeMat, A);
    compositeMat = cat(3, compositeMat, B);
    compositeMat = cat(3, compositeMat, GMA);
    compositeMat = cat(3, compositeMat, GMB);
      
    
    for ch = 1:size(compositeMat,3)
        for scale = 1:kscale
            % chroma features only in half scale
            if (ch >= 5 ) && (scale == 1) 
                continue;  
            end
            y_scale = imresize(compositeMat(:,:,ch), 2 ^ (-(scale - 1)));
            
             % Leer el archivo XML
                %docNode = xmlread('y_scale.xml');
                
                % Extraer elementos del archivo XML
                %rows = str2double(docNode.getElementsByTagName('rows').item(0).getFirstChild.getData);
                %cols = str2double(docNode.getElementsByTagName('cols').item(0).getFirstChild.getData);
                %dataNode = docNode.getElementsByTagName('data').item(0).getFirstChild.getData;
                
                % Convertir los datos de texto a matriz numérica
                %dataStr = strtrim(regexprep(char(dataNode), '[^0-9. ]', ''));
                %dataNum = str2double(split(dataStr)); % Convertir a vector numérico
                
                % Verificar que la longitud de dataNum sea rows*cols
                %if length(dataNum) ~= rows*cols
                    %error('La cantidad de datos no coincide con las dimensiones especificadas.');
                %end
                
                % Cambiar el vector a una matriz 2D
                %xmlMatrix = reshape(dataNum, [cols, rows])';
                
                % Comparar con tu matriz y_scale
                % Calcular el coeficiente de correlación de Pearson
                %coeficientePearson = corrcoef(y_scale(:), xmlMatrix(:));
                
                % El resultado es una matriz 2x2, pero nos interesa el valor fuera de la diagonal
                %coeficiente = coeficientePearson(1,2);




            feats = [feats rapique_basic_extractor(y_scale)];
        end
    end

% Detener el contador de tiempo
elapsed_time = cputime - ti;
upd_FuncInfo("RAPIQUE_spatial_features",elapsed_time);
end

function [gspace_img, ksplit_img] = gen_DoG(img, kband)
w = size(img, 2);
h = size(img, 1);
kval = 1.6;
gspace_img = zeros(h, w, kband);
ksplit_img = zeros(h, w, kband);
gspace_img(:,:,1) = img;
for band = 2:kband
    sigma = kval ^ (band - 2);
    ws = ceil(2*(3*sigma + 1));
    h = fspecial('gaussian', ws, sigma);
    gspace_img(:,:,band) = imfilter(gspace_img(:,:,1), h, 'replicate');
end
ksplit_img(:,:,kband) = gspace_img(:,:,kband);
for band = 1:kband-1
    ksplit_img(:,:,band) = gspace_img(:,:,band) - gspace_img(:,:,band+1);
end
end
