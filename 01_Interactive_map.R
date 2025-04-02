library(leaflet)
library(dplyr)
library(htmlwidgets)

# Cargar los datos GPS descargados previamente
gps.df <- read.csv("gps_data.csv")

# Convertir la columna de fecha a formato adecuado
gps.df$datetimeGMT <- as.POSIXct(gps.df$datetimeGMT, format="%Y-%m-%d %H:%M:%S", tz="GMT")

# Crear la paleta de colores para cada birdID
paleta_colores <- colorFactor(palette = "Set1", domain = gps.df$birdID)

# Crear el mapa base
mapa <- leaflet() %>%
  addTiles()

# Agregar capas de tracks por cada individuo
grupos <- unique(gps.df$birdID)  # Obtener los ID únicos

for (bird in grupos) {
  datos_individual <- gps.df %>% filter(birdID == bird)  # Filtrar datos por birdID
  
  mapa <- mapa %>%
    addPolylines(
      lng = ~longitude, lat = ~latitude, 
      data = datos_individual,
      color = 'darkgrey',
      weight = 0.75, opacity = 0.7,
      group = bird  # Asigna el track al mismo grupo
    ) %>%
    addCircleMarkers(
      lng = ~longitude, lat = ~latitude, 
      data = datos_individual,
      radius = 0.5, color = ~paleta_colores(birdID), 
      popup = ~paste("Ave:", birdID, "<br>Fecha:", datetimeGMT),
      group = bird  # Asigna un grupo con el nombre del birdID
    ) 
}

# Agregar control de capas para activar/desactivar individuos
mapa <- mapa %>%
  addLayersControl(
    overlayGroups = grupos,  # Usa los birdID como grupos de control
    options = layersControlOptions(collapsed = FALSE)  # Mostrar la lista expandida
  )

# Guardar el mapa como archivo HTML
saveWidget(mapa, file = "docs/mapa_interactivo.html", selfcontained = TRUE)
