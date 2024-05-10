''' Code to reform csv
import pandas as pd
import csv
# Leer el archivo CSV como una sola columna
df = pd.read_csv("result\\function_stats_Qualcomm.csv", header=None)

# Crear un nuevo DataFrame para almacenar los datos reformateados
new_df = pd.DataFrame(columns=["VideoName", "Function_name", "execution_count", "exec_time_avg"])

# Iterar sobre cada fila en el DataFrame original
for index, row in df.iterrows():
    # Saltar la primera fila (encabezados)
    if index == 0:
        continue

    # Obtener la fila como una cadena y eliminar las comillas dobles adicionales
    line = row[0].replace('""', '"')

    # Dividir la línea en campos por comas
    fields = line.split(',')

    # Reformatear los campos y agregarlos al nuevo DataFrame
    new_df.loc[len(new_df)] = {
        "VideoName": f'"{fields[0]}"',
        "Function_name": fields[1],
        "execution_count": float(fields[2]),
        "exec_time_avg": float(fields[3])
    }

# Guardar el nuevo DataFrame en un nuevo archivo CSV
new_df.to_csv("result\\reformatted_function_stats_LIVE_Qualcomm.csv", index=False, quoting=csv.QUOTE_NONE, escapechar='\\')
'''
import pandas as pd
import os

# Ruta del directorio que contiene los archivos CSV
csv_directory = "result"
output_file = "result\\RAPIQUE_time_tests_CPP.xlsx"
# Lista para almacenar las hojas de Excel
excel_sheets = []
# Lista para almacenar los datos de all_datasets_times
all_datasets_times_data = []

# Verificar si el archivo Excel ya existe
if os.path.exists(output_file):
    # Si existe, eliminarlo
    os.remove(output_file)

# Creamos un DataFrame vacío y lo escribimos en el archivo Excel
with pd.ExcelWriter(output_file, mode='w') as writer:
    pd.DataFrame().to_excel(writer, index=False)

# Iterar sobre los archivos CSV en el directorio
for filename in os.listdir(csv_directory):
    if filename.startswith("function_stats_CPP") and filename.endswith(".xlsx"):
        # Obtener el dataset_name
        dataset_name = filename.split("\\")[-1].split("function_stats_CPP_")[-1][:-4]
        print(dataset_name)
        # Leer el archivo CSV
        csv_file = os.path.join(csv_directory, filename)
        df = pd.read_excel(csv_file)

        # Eliminar espacios en blanco adicionales en los nombres de las columnas
        df.columns = df.columns.str.strip()

        # Calcular el tiempo total por función
        function_stats = df.groupby('FunctionName')['AverageExecTime'].sum().reset_index()
        function_stats.rename(columns={'AverageExecTime': 'TotalTime'}, inplace=True)

        # Calcular el tiempo promedio por función en todo el dataset
        total_videos = df['VideoName'].nunique()
        function_stats['TotalTime (min)'] = function_stats['TotalTime']/60.0
        function_stats['AverageTotalTime'] = function_stats['TotalTime'] / total_videos

        # Guardar los resultados en la primera hoja del archivo Excel

        with pd.ExcelWriter(output_file, mode='a') as writer:
            # Escribir los resultados de las funciones en una nueva hoja
            function_stats.to_excel(writer, sheet_name=f"functs_{dataset_name}", index=False)

            # Construir la tabla de videos
            videos_df = df[df['FunctionName'] == "RAPIQUE_video"][['VideoName', 'AverageExecTime']]
            videos_df.columns = ['VideoName', 'Time']
            videos_df.to_excel(writer, sheet_name=f"videos_{dataset_name}", index=False)

        # Guardar el nombre de la hoja en la lista
        excel_sheets.extend([f"functs_{dataset_name}", f"videos_{dataset_name}"])

# Crear la tabla "all_datasets_times" solo si se procesaron archivos CSV
if excel_sheets:
    # Crear DataFrame para "all_datasets_times"
    all_datasets_times = pd.DataFrame(columns=['Dataset', 'TotalTime', 'TotalTime (min)', 'TotalTime (hr)',
                                               'AverageVideoTime'])

    # Iterar sobre las hojas creadas y obtener los datos
    for sheet_name in excel_sheets:
        if sheet_name.startswith("videos_"):
            dataset_name = sheet_name[7:]
            print('sheet name: ' + dataset_name)
            videos_sheet = pd.read_excel(output_file, sheet_name=sheet_name)
            TotalTime = videos_sheet['Time'].sum()
            avg_video_time = TotalTime / len(videos_sheet)
            all_datasets_times_data.append({
                'Dataset': dataset_name,
                'TotalTime': TotalTime,
                'TotalTime (min)': TotalTime/60,
                'TotalTime (hr)': TotalTime/3600,
                'AverageVideoTime': avg_video_time
            })

    # Escribir los resultados en la hoja "all_datasets_times"
    all_datasets_times = pd.DataFrame(all_datasets_times_data)
    if not all_datasets_times.empty:
        with pd.ExcelWriter(output_file, mode='a') as writer:
            all_datasets_times.to_excel(writer, sheet_name="all_datasets_times", index=False)