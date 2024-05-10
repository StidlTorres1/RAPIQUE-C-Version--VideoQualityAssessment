% Cargar el archivo original
data = load('KoNViD.mat');

% Extraer los nombres de los campos
fields = fieldnames(data);

% Índices a conservar
indices = [660, 1108, 277, 296, 516, 172, 454, 196, 236, 712, 385, 785, 44, 78, 752, 902, 1165, 63, 576, 996, 900, 309, 27, 1046, 905, 221, 166, 780, 149, 1090, 1103, 991, 1177, 912, 968, 661, 491, 839, 960, 820, 1048, 213, 958, 579, 723, 271, 65, 1169, 1043, 1033, 37, 41, 606, 959, 342, 359, 972, 336, 983, 828, 1191, 720, 124, 351, 1083, 1020, 898, 1045, 219, 574, 55, 225, 750];

% Crear una nueva estructura para el archivo resultante
new_data = struct();

for i = 1:length(fields)
    field = fields{i};
    if isnumeric(data.(field)) || iscell(data.(field))
        if size(data.(field), 1) == 1200 || size(data.(field), 2) == 1200
            % Filtrar datos según los índices
            if size(data.(field), 1) == 1200
                new_data.(field) = data.(field)(indices, :);
            elseif size(data.(field), 2) == 1200
                new_data.(field) = data.(field)(:, indices);
            end
        else
            new_data.(field) = data.(field);
        end
    else
        new_data.(field) = data.(field);
    end
end

% Ajustar ref_ids si existe en los datos
if isfield(new_data, 'ref_ids')
    new_data.ref_ids = (1:length(indices))'; % Crea un vector columna
end

% Guardar el nuevo archivo en formato HDF5
save('KoNViD-1kinfo2.mat', '-struct', 'new_data', '-v7.3');