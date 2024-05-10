function upd_FuncInfo(func_name,varargin)
    ti = cputime;
    if ~isempty(varargin)
        time = varargin{1}; 
    else
        time = 0; 
    end

    data = load('func_info.mat');
    video_shortname = data.video_shortname;
    func_info = data.func_info;
    function_names = {          %idx = function id
            "calc_RAPIQUE_features";%1
            "calc_RAPIQUE_features/deep_learning"; %14
            "calc_RAPIQUE_features/temporal NSS"; %15
            "clipValue";            %2
            "convertRGBToHSI";        %3
            "convertRGBToLAB";       %4
            "convertRGBToLMS";       %5
            "convertRGBToYuv";       %6
            "convertYuvToRgb";       %7
            "gauDerivative";        %8
            "loadFileYuv";          %9
            "progressbar";          %10
            "rapique_basic_extractor";%11
            "RAPIQUE_spatial_features";%12
            "saveFileYuv";          %13  
        };

    
    if ~strcmp(func_name, 'next')
        % Find idx
        for i = 1:length(function_names)
            if strcmp(func_name, function_names{i})
                idx = i;
                break;
            end
        end
        if isempty(idx)
            error("function name not found");
        end
        func_info(idx,1) = func_info(idx,1)+1;
        func_info(idx,2) = func_info(idx,2)+ time;
        %disp(func_info(idx,:))
    else
        %disp("aqui va escribir el csv") 
        
        output_file = "function_stats.csv";
        if exist(output_file, 'file')
            fid = fopen(output_file, 'a');  % Abre en modo "a" para anexar
        else
            fid = fopen(output_file, 'w');  % Crea un nuevo archivo
            fprintf(fid, '"%s","%s",%s,%s\n', "video_shortname", "Function_name","execution_count","exec_time_avg");
        end   
        if fid == -1
            error('No se pudo abrir el archivo para escritura.');
        end

        % Escribe los datos para cada función
        for func_id = 1:length(function_names)
            func_name = function_names{func_id};
            count = func_info(func_id, 1);
            average_time = func_info(func_id,2)/count;
            fprintf(fid, '"%s","%s",%d,%d\n', video_shortname, func_name, count,average_time);
        end
        
        fclose(fid);
        disp(['Archivo CSV "' output_file '" creado o actualizado exitosamente.']);
        func_info = zeros(length(function_names),2);
    end
    save('func_info.mat',"func_info","video_shortname");
    FuncinfoTime  = cputime - ti;
end

    