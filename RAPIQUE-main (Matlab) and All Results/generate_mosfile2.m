% Ruta de la carpeta que contiene los archivos de video
rutaCarpeta = 'X:\RAPIQUE_proyecto\RAPIQUE-project\YOUTUBE_UGC_videos';

% Obtener una lista de todos los archivos de video en la carpeta
archivosVideo = dir(fullfile(rutaCarpeta, '*.mp4')); 

% Crear una celda para almacenar las características
caracteristicas = cell(length(archivosVideo), 5); % Ahora 5 columnas: nombre, height, width, framerate, MOS

% Iterar a través de cada archivo de video
for i = 1:length(archivosVideo)
    nombreArchivo = archivosVideo(i).name;
    [filepath,name,ext] = fileparts(nombreArchivo); % Extrae el nombre del archivo sin la extensión
    
    % Extrae la parte del nombre antes del segundo guión bajo
    indices = strfind(name, '_');
    if length(indices) >= 2
        name = name(1:indices(2)-1);
    end
    
    % Leer el archivo xlsx y la hoja MOS
    tabla = readtable('ruta_al_archivo.xlsx', 'Sheet', 'MOS', 'VariableNamingRule', 'preserve'); % Reemplaza 'ruta_al_archivo.xlsx' con la ruta al archivo xlsx
    vid = tabla.('vid'); % Columna 'vid'
    mos_full = tabla.('MOS full'); % Columna 'MOS full'
    % Buscar el valor MOS correspondiente
    idx = strcmp(vid, name); % Ahora compara 'vid' con la parte del nombre del archivo antes del segundo guión bajo
    
    % Si el nombre del video no se encuentra en 'vid', saltar a la siguiente iteración
    if ~any(idx)
        continue;
    end
    
    rutaCompleta = fullfile(rutaCarpeta, nombreArchivo)
    
    % Crear un objeto de VideoReader
    videoObjeto = VideoReader(rutaCompleta);
    
    % Extraer las características
    height = videoObjeto.Height;
    width = videoObjeto.Width;
    framerate = videoObjeto.FrameRate;
    mos = mos_full(idx); % Obtiene el valor MOS correspondiente
    
    % Almacenar las características en la matriz
    caracteristicas(i, :) = {name, height, width, framerate, mos};
end

% Eliminar las filas vacías
caracteristicas = caracteristicas(~cellfun('isempty', caracteristicas(:, 1)), :);

% Crear un archivo CSV con las características
tablaCaracteristicas = cell2table(caracteristicas, 'VariableNames', {'nombre', 'height', 'width', 'framerate', 'MOS'}); % Agrega 'MOS' a los nombres de las variables

% Guardar la tabla en un archivo CSV
nombreArchivoCSV = 'Youtube_UGC_metadata.csv';
writetable(tablaCaracteristicas, nombreArchivoCSV);

disp(['Se han guardado las características en el archivo "', nombreArchivoCSV, '"']);


%% Include MOS values

% Leer los archivos CSV
realignmentData = readtable('X:\RAPIQUE_proyecto\RAPIQUE-project\CVD2014_ratings\Realignment_MOS.csv','Delimiter',';');
metadataData = readtable('X:\RAPIQUE_proyecto\RAPIQUE-project\RAPIQUE-VideoQualityAssessment\RAPIQUE-main\mos_files\CVD2014_metadata.csv');
% Crear la nueva columna "MOS" en metadataData
metadataData.MOS = str2double(strrep(realignmentData.('Realignment_MOS'), ',', '.'));
% Guardar la tabla actualizada en un nuevo archivo CSV
writetable(metadataData, 'CVD_2014_metadata.csv');


