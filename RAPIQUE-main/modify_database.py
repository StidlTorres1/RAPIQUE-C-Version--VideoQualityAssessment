import pandas as pd

# Cargar el archivo csv
df = pd.read_csv('mos_files\YOUTUBE_UGC_metadata.csv')

# Reorganizar las columnas y agregar las que faltan
dff = df[['flickr_id', 'mos', 'width', 'height']]
#dff.loc[dff['flickr_id'].index, 'flickr_id'] = dff['flickr_id'].str[:-4]


# Agregar las columnas faltantes con valor 0 en el orden correcto
dff['pixfmt'] = 0
dff['framerate'] = df['framerate']
dff['nb_frames'] = 0
dff['bitdepth'] = 0
dff['bitrate'] = 0



# Eliminar la columna 'framerate' antigua
#df = df.drop(columns=['framerate'])

# Guardar el nuevo dataframe en un nuevo archivo csv
dff.to_csv('mos_files\YOUTUBE_UGC_metadata_formatted.csv', index=False)
