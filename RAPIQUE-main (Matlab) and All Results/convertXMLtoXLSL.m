function xmlToExcel(xmlFile, excelFile)
    % Leer el archivo XML
    try
        xmlDoc = xmlread(xmlFile);
    catch
        error('Failed to read XML file %s.',xmlFile);
    end
    
    % Extraer elementos Video
    videos = xmlDoc.getElementsByTagName('Video');
    numVideos = videos.getLength;
    data = {};
    
    % Iterar sobre cada Video
    for i = 0:numVideos-1
        video = videos.item(i);
        videoName = char(video.getAttribute('name'));
        
        % Extraer elementos Function
        functions = video.getElementsByTagName('Function');
        numFunctions = functions.getLength;
        
        % Iterar sobre cada Function
        for j = 0:numFunctions-1
            functionElement = functions.item(j);
            functionName = char(functionElement.getAttribute('name'));
            executionCount = char(functionElement.getElementsByTagName('ExecutionCount').item(0).getFirstChild.getData);
            averageExecTime = char(functionElement.getElementsByTagName('AverageExecTime').item(0).getFirstChild.getData);
            
            % Agregar datos a la matriz
            data(end+1, :) = {videoName, functionName, executionCount, averageExecTime};
        end
    end
    
    % Crear tabla y escribir a archivo Excel
    T = cell2table(data, 'VariableNames', {'VideoName', 'FunctionName', 'ExecutionCount', 'AverageExecTime'});
    writetable(T, excelFile);
    
    disp(['Datos guardados exitosamente en ', excelFile]);
end

%% To convert all files.

% Directorio donde se encuentran los archivos XML
directorio = 'X:\RAPIQUE_proyecto\RAPIQUE-project\RAPIQUE-VideoQualityAssessment\RAPIQUE-main\result';

% Obtén una lista de todos los archivos XML que comienzan con "function_stats_CPP"
archivos = dir(fullfile(directorio, 'function_stats_CPP*.xml'));

% Recorre cada archivo en la lista
for i = 1:length(archivos)
    % Ruta completa del archivo XML
    archivo_xml = fullfile(directorio, archivos(i).name);
    
    % Crea el nombre del archivo de salida XLSX reemplazando la extensión .xml por .xlsx
    archivo_xlsx = strrep(archivo_xml, '.xml', '.xlsx');
    
    % Llama a la función xmlToExcel con los argumentos de entrada y salida
    xmlToExcel(archivo_xml, archivo_xlsx);
end

%% convert 1 file
xmlToExcel("X:\RAPIQUE_proyecto\RAPIQUE-project\RAPIQUE-VideoQualityAssessment\RAPIQUE-main\result\function_stats_CPP_all_combined.xml","X:\RAPIQUE_proyecto\RAPIQUE-project\RAPIQUE-VideoQualityAssessment\RAPIQUE-main\result\function_stats_CPP_all_combined.xlsx")