% % Cargar el archivo original
% data = load('KoNViD-1kinfo.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [660, 1108, 277, 296, 516, 172, 454, 196, 236, 712, 385, 785, 44, 78, 752, 902, 1165, 63, 576, 996, 900, 309, 27, 1046, 905, 221, 166, 780, 149, 1090, 1103, 991, 1177, 912, 968, 661, 491, 839, 960, 820, 1048, 213, 958, 579, 723, 271, 65, 1169, 1043, 1033, 37, 41, 606, 959, 342, 359, 972, 336, 983, 828, 1191, 720, 124, 351, 1083, 1020, 898, 1045, 219, 574, 55, 225, 750];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 1200 || size(data.(field), 2) == 1200
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 1200
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 1200
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Guardar el nuevo archivo en formato HDF5
% save('KoNViD-1kinfo3.mat', '-struct', 'new_data', '-v7.3');

% %%Konvik1k
% % Cargar el archivo original
% data = load('KoNViD-1kinfo.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [660, 1108, 277, 296, 516, 172, 454, 196, 236, 712, 385, 785, 44, 78, 752, 902, 1165, 63, 576, 996, 900, 309, 27, 1046, 905, 221, 166, 780, 149, 1090, 1103, 991, 1177, 912, 968, 661, 491, 839, 960, 820, 1048, 213, 958, 579, 723, 271, 65, 1169, 1043, 1033, 37, 41, 606, 959, 342, 359, 972, 336, 983, 828, 1191, 720, 124, 351, 1083, 1020, 898, 1045, 219, 574, 55, 225, 750];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 1200 || size(data.(field), 2) == 1200
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 1200
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 1200
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
%     % Modificar 'video_names'
%     if strcmp(field, 'video_names')
%         for j = 1:numel(new_data.(field))
%             name = new_data.(field){j};
%             underscore_idx = strfind(name, '_');
%             dot_idx = strfind(name, '.mp4');
%             if ~isempty(underscore_idx) && ~isempty(dot_idx)
%                 new_data.(field){j} = [name(1:underscore_idx(1)-1), '.mp4'];
%             end
%         end
%     end
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Guardar el nuevo archivo en formato HDF5
% save('KoNViD-1kinfo2.mat', '-struct', 'new_data', '-v7.3');


% %%CVD2014
% % Cargar el archivo original
% data = load('CVD2014info.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [227, 25, 108, 160, 11, 37, 181, 208, 211, 128, 164, 143, 55, 191];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 234 || size(data.(field), 2) == 234
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 234
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 234
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
%     % Modificar 'video_names'
%     if strcmp(field, 'video_names')
%         for j = 1:numel(new_data.(field))
%             name = new_data.(field){j};
%             last_slash_idx = find(name == '/', 1, 'last');
%             if ~isempty(last_slash_idx)
%                 name = name(last_slash_idx + 1:end); % Remove everything before the last slash
%             end
%             name = strrep(name, '.avi', '.mp4'); % Replace .avi with .mp4
%             new_data.(field){j} = name;
%         end
%     end
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Guardar el nuevo archivo en formato HDF5
% save('CVD2014info2.mat', '-struct', 'new_data', '-v7.3');


% %%Qualcom
% % Cargar el archivo original
% data = load('LIVE-Qualcomminfo.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [167, 90, 135, 76, 183, 37, 28, 158, 93, 108, 73, 63, 78];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 208 || size(data.(field), 2) == 208
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 208
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 208
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
%     % Modificar 'video_names'
%     if strcmp(field, 'video_names')
%         for j = 1:numel(new_data.(field))
%             name = new_data.(field){j};
%             last_slash_idx = find(name == '/', 1, 'last');
%             if ~isempty(last_slash_idx)
%                 name = name(last_slash_idx + 1:end); % Remove everything before the last slash
%             end
%             name = strrep(name, '.yuv', '.mp4'); % Replace .avi with .mp4
%             new_data.(field){j} = name;
%         end
%     end
%     if strcmp(field, 'video_format')
%         new_data = rmfield(new_data, 'video_format');
%         new_data.video_format='RGB';
%     end
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Guardar el nuevo archivo en formato HDF5
% save('LIVE-Qualcomminfo2.mat', '-struct', 'new_data', '-v7.3');

%% LVQC
% % Cargar los datos desde el archivo CSV
% data = readtable('LIVE_VQC_metadata.csv');
% 
% % Extraer y procesar las columnas necesarias
% unique_widths = unique(data.width)';
% unique_heights = unique(data.height)';
% video_names = data.File; % Asumiendo que 'File' es la columna con los nombres de los videos
% scores = data.MOS; % Asumiendo que 'MOS' es la columna con los puntajes
% 
% % Crear la propiedad video_format
% video_format = 'RGB';
% 
% % Crear ref_ids desde 1 hasta el número de videos
% ref_ids = (1:height(data))';
% 
% % Preparar la estructura para guardar en el archivo .mat
% mat_data = struct();
% mat_data.video_format = video_format;
% mat_data.width = unique_widths;
% mat_data.height = unique_heights;
% mat_data.video_names = video_names;
% mat_data.scores = scores;
% mat_data.ref_ids = ref_ids;
% 
% % Guardar en un archivo .mat en formato HDF5
% save('LIVE_VQCinfo.mat', '-struct', 'mat_data', '-v7.3');
% Cargar el archivo original

%% LVQC
% data = load('LIVE_VQCinfo.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [123, 187, 550, 344, 497, 225, 374, 198, 569, 487, 367, 208, 392, 480, 248, 568, 29, 278, 5, 470, 391, 96, 479, 398, 420, 418, 20, 97, 62, 125, 231, 183, 462, 19, 126, 564];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 585 || size(data.(field), 2) == 585
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 585
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 585
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Guardar el nuevo archivo en formato HDF5
% save('LIVE_VQCinfo2.mat', '-struct', 'new_data', '-v7.3');

% % Cargar los datos desde el archivo .mat
% data = load('LIVE_VQCinfo.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [123, 187, 550, 344, 497, 225, 374, 198, 569, 487, 367, 208, 392, 480, 248, 568, 29, 278, 5, 470, 391, 96, 479, 398, 420, 418, 20, 97, 62, 125, 231, 183, 462, 19, 126, 564];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 585 || size(data.(field), 2) == 585
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 585
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 585
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Crear la propiedad index
% % Asumiendo que 'video_names' tiene un total de N elementos
% N = numel(new_data.video_names);  % Asegúrate de que N es 36
% M = 1000;  % Total de filas
% max_val = 585;  % Valor máximo que puede tomar cada entrada
% 
% % Inicializar la matriz index
% index = zeros(M, N);
% 
% % Llenar la matriz
% for i = 1:M
%     available = 1:max_val;
%     for j = 1:N
%         if numel(available) < 1
%             error('No hay suficientes valores únicos disponibles para evitar duplicados en una fila.');
%         end
%         pick = randi(length(available));  % Elegir un índice aleatorio de los disponibles
%         index(i, j) = available(pick);  % Asignar el valor elegido a la matriz
%         available(pick) = [];  % Eliminar el valor elegido de los disponibles
%     end
% end
% 
% % Asumiendo que el resto del código para ajustar datos y guardarlos sigue aquí
% % Por ejemplo:
% new_data.index = index;
% % Crear la propiedad max_len
% new_data.max_len = 830;
% 
% % Guardar el nuevo archivo en formato HDF5
% save('LIVE_VQCinfo2.mat', '-struct', 'new_data', '-v7.3');




% UGC
% % Cargar los datos desde el archivo CSV
% data = readtable('YOUTUBE_UGC_metadata.csv');
% 
% % Identificar las filas donde 'vid' coincide con 'video_shortname'
% [~, idx] = ismember(data.vid, data.video_shortname);
% 
% % Filtrar los datos para incluir solo aquellos que coinciden
% filtered_data = data(logical(idx), :);
% 
% % Extraer y procesar las columnas necesarias
% unique_widths = unique(filtered_data.width)';
% unique_heights = unique(filtered_data.height)';
% video_names = filtered_data.vid; % Usando 'vid' como nombre de video
% video_names = cellfun(@(x) [x '.mp4'], video_names, 'UniformOutput', false); % Agregando .mp4 a cada nombre
% scores = filtered_data.MOSFull; % Usando 'MOSFull' como los puntajes
% 
% % Crear la propiedad video_format
% video_format = 'RGB';
% 
% % Crear ref_ids desde 1 hasta el número de videos filtrados
% ref_ids = (1:height(filtered_data))';
% 
% % Preparar la estructura para guardar en el archivo .mat
% mat_data = struct();
% mat_data.video_format = video_format;
% mat_data.width = unique_widths;
% mat_data.height = unique_heights;
% mat_data.video_names = video_names;
% mat_data.scores = scores;
% mat_data.ref_ids = ref_ids;
% 
% % Guardar en un archivo .mat en formato HDF5
% save('UGC.mat', '-struct', 'mat_data', '-v7.3');


%%UGC
% % Cargar los datos desde el archivo .mat
% data = load('UGC.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [736, 251, 416, 1013, 843, 336, 877, 325, 400, 895, 682, 49, 530, 793, 53, 397, 685, 731, 154, 1037, 288, 332, 859, 116, 289, 505, 39, 851, 1033, 175, 343, 60, 495, 1038, 870, 730, 368, 988, 592, 674, 184, 81, 623, 316, 462, 449, 402, 499, 260, 124, 258, 952, 247, 962, 433, 171, 47, 27, 707, 319, 1003, 232, 361, 510];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 1045 || size(data.(field), 2) == 1045
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 1045
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 1045
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Añadir sufijo '_crf_10_ss_00_t_20.0' antes de '.mp4' a cada nombre de video
% suffix = '_crf_10_ss_00_t_20.0';
% new_data.video_names = cellfun(@(x) [x(1:end-4) suffix '.mp4'], new_data.video_names, 'UniformOutput', false);
% 
% % Crear la propiedad index
% N = numel(new_data.video_names);  % Asegúrate de que N es correcto
% M = 1000;  % Total de filas
% max_val = 1045;  % Valor máximo que puede tomar cada entrada
% 
% % Inicializar la matriz index
% index = zeros(M, N);
% 
% % Llenar la matriz
% for i = 1:M
%     available = 1:max_val;
%     for j = 1:N
%         if numel(available) < 1
%             error('No hay suficientes valores únicos disponibles para evitar duplicados en una fila.');
%         end
%         pick = randi(length(available));  % Elegir un índice aleatorio de los disponibles
%         index(i, j) = available(pick);  % Asignar el valor elegido a la matriz
%         available(pick) = [];  % Eliminar el valor elegido de los disponibles
%     end
% end
% new_data.index = index;
% 
% % Crear la propiedad max_len
% new_data.max_len = 830;
% 
% % Guardar el nuevo archivo en formato HDF5
% save('UGC2.mat', '-struct', 'new_data', '-v7.3');




% % Cargar el archivo .mat
% data = load('UGC2.mat');
% 
% % Extraer la lista de nombres de videos
% video_names = data.video_names; % Asegúrate de usar el nombre correcto de la estructura
% 
% % Definir la carpeta de origen donde buscar los videos
% source_folder = 'C:\Users\stidl\Desktop\Universidad\RAPIQUE-VideoQualityAssessment\dataBase\UGC';
% 
% % Definir la carpeta de destino donde copiar los videos encontrados
% destination_folder = 'C:\Users\stidl\Desktop\Universidad\Metrics\databaseAll\UGC';
% 
% % Crear la carpeta de destino si no existe
% if ~exist(destination_folder, 'dir')
%     mkdir(destination_folder);
% end
% 
% % Bucle para buscar y copiar los archivos
% for i = 1:length(video_names)
%     % Construir la ruta completa del archivo actual
%     current_file = fullfile(source_folder, video_names{i});
% 
%     % Verificar si el archivo existe
%     if exist(current_file, 'file')
%         % Construir la ruta completa de destino
%         destination_file = fullfile(destination_folder, video_names{i});
% 
%         % Copiar el archivo a la nueva ubicación
%         copyfile(current_file, destination_file);
%     else
%         % Opcional: mostrar un mensaje si el archivo no se encuentra
%         fprintf('Archivo no encontrado: %s\n', current_file);
%     end
% end
% 
% % Mensaje de finalización
% disp('Proceso completado.');

% Cargar el archivo .mat
data = load('LIVE_VQCinfo2.mat');

% Extraer la lista de nombres de videos
video_names = data.video_names; % Asegúrate de usar el nombre correcto de la estructura

% Definir la carpeta de origen donde buscar los videos
source_folder = 'C:\Users\stidl\Desktop\Universidad\RAPIQUE-VideoQualityAssessment\dataBase\LVQC';

% Definir la carpeta de destino donde copiar los videos encontrados
destination_folder = 'C:\Users\stidl\Desktop\Universidad\Metrics\databaseAll\LIVE_VQC';

% Crear la carpeta de destino si no existe
if ~exist(destination_folder, 'dir')
    mkdir(destination_folder);
end

% Bucle para buscar y copiar los archivos
for i = 1:length(video_names)
    % Construir la ruta completa del archivo actual
    current_file = fullfile(source_folder, video_names{i});
    
    % Verificar si el archivo existe
    if exist(current_file, 'file')
        % Construir la ruta completa de destino
        destination_file = fullfile(destination_folder, video_names{i});
        
        % Copiar el archivo a la nueva ubicación
        copyfile(current_file, destination_file);
    else
        % Opcional: mostrar un mensaje si el archivo no se encuentra
        fprintf('Archivo no encontrado: %s\n', current_file);
    end
end

% Mensaje de finalización
disp('Proceso completado.');



% % Cargar el archivo original
% data = load('KoNViD-1kinfo.mat');
% 
% % Extraer los nombres de los campos
% fields = fieldnames(data);
% 
% % Índices a conservar
% indices = [660, 1108, 277, 296, 516, 172, 454, 196, 236, 712, 385, 785, 44, 78, 752, 902, 1165, 63, 576, 996, 900, 309, 27, 1046, 905, 221, 166, 780, 149, 1090, 1103, 991, 1177, 912, 968, 661, 491, 839, 960, 820, 1048, 213, 958, 579, 723, 271, 65, 1169, 1043, 1033, 37, 41, 606, 959, 342, 359, 972, 336, 983, 828, 1191, 720, 124, 351, 1083, 1020, 898, 1045, 219, 574, 55, 225, 750];
% 
% % Crear una nueva estructura para el archivo resultante
% new_data = struct();
% 
% for i = 1:length(fields)
%     field = fields{i};
%     if isnumeric(data.(field)) || iscell(data.(field))
%         if size(data.(field), 1) == 1200 || size(data.(field), 2) == 1200
%             % Filtrar datos según los índices
%             if size(data.(field), 1) == 1200
%                 new_data.(field) = data.(field)(indices, :);
%             elseif size(data.(field), 2) == 1200
%                 new_data.(field) = data.(field)(:, indices);
%             end
%         else
%             new_data.(field) = data.(field);
%         end
%     else
%         new_data.(field) = data.(field);
%     end
% end
% 
% % Eliminar el campo 'index' si existe en los datos
% if isfield(new_data, 'index')
%     new_data = rmfield(new_data, 'index');
%     new_data = rmfield(new_data, 'max_len');
% end
% 
% % Ajustar ref_ids si existe en los datos
% if isfield(new_data, 'ref_ids')
%     new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
% end
% 
% % Guardar el nuevo archivo en formato HDF5
% save('KoNViD-1kinfo4.mat', '-struct', 'new_data', '-v7.3');