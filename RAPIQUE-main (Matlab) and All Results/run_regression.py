import os
import subprocess


# Ruta al intérprete de Python de tu entorno virtual
python_path = '.\\venv\\Scripts\\python.exe'
# Directorio donde se encuentran los archivos .csv
dir_path = 'feat_files'
script_path = 'evaluate_bvqa_features_regression.py'
# Recorre todos los archivos en el directorio
for filename in os.listdir(dir_path):
    # Comprueba si el archivo es un archivo .csv
    if filename.endswith('combined_RAPIQUE_feats_CPP.xml'):
        # Extrae el nombre del dataset del nombre del archivo

        #dataset_name = filename.split("f_RAPIQUE_feats")[-1]
        dataset_name = filename.replace('_RAPIQUE_feats_CPP.xml', '')
        if dataset_name.endswith('i9'):
            mos_file = dataset_name[:-3]
        else:
            mos_file = dataset_name
        # Define los argumentos para el script de Python
        args = [
            '--dataset_name', dataset_name,
            '--feature_file', f'feat_files\\{dataset_name}_RAPIQUE_feats_CPP.xml',
            '--mos_file', f'mos_files\\{mos_file}_metadata.csv',
            '--out_file', f'result\\{dataset_name}_RAPIQUE_SVR_corr_CPP.mat',
            '--log_file', f'logs\\{dataset_name}_RAPIQUE_SVR_CPP.log'
        ]

        # Ejecuta el script de Python con los argumentos definidos
        subprocess.run([python_path, script_path] + args)
