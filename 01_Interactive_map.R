library(leaflet)
library(dplyr)
library(htmlwidgets)

# Cargar los datos GPS descargados previamente
gps.df <- read.csv("gps_data.csv")

# Convertir la columna de fecha a formato adecuado
gps.df$datetimeGMT <- as.POSIXct(gps.df$datetimeGMT, format="%Y-%m-%d %H:%M:%S", tz="GMT")

# Filtrar datos de los últimos 2 días
lst_days <- as.POSIXct(Sys.time(), tz="GMT") - (2 * 24 * 60 * 60)  # Hace 2 días
gps.df2 <- gps.df %>% filter(datetimeGMT >= lst_days)

# Crear la paleta de colores para cada birdID
pal.colors <- colorFactor(palette = "Set1", domain = gps.df$birdID)

# Crear el mapa base
leafletOptions <- leaflet::leafletOptions(preferCanvas = TRUE)
map <- leaflet(options = leafletOptions) %>%
  addTiles(options = tileOptions(maxZoom = 10))

# Agregar capas de tracks por cada individuo
grupos <- unique(gps.df$birdID)  # Obtener los ID únicos

for (bird in grupos) {
  gps.ind <- gps.df %>% filter(birdID == bird)  # Filtrar datos por birdID
  lst_pos <- gps.ind %>% filter(datetimeGMT == max(datetimeGMT))
  map <- map %>%
    addPolylines(
      lng = ~longitude, lat = ~latitude, 
      data = gps.ind,
      color = 'darkgrey',
      weight = 0.75, opacity = 0.7,
      group = bird  # Asigna el track al mismo grupo
    ) %>%
    addCircleMarkers(
      lng = ~longitude, lat = ~latitude, 
      data = gps.ind,
      radius = 0.5,
      color = ~pal.colors(birdID), 
      popup = ~paste("ID:", birdID, "<br>Date:", datetimeGMT, "Sex:", sex),
      group = bird  # Asigna un grupo con el nombre del birdID
    ) %>% 
    addAwesomeMarkers(
      lng = ~longitude, lat = ~latitude,
      data = lst_pos,
      icon = awesomeIcons(
        icon = 'star', library = 'fa', markerColor = 'red'
      ),
      popup = ~paste("ID:", birdID, "<br>Fecha:", datetimeGMT, "Sex:", sex),
      group = bird
    )
}

# Agregar control de capas para activar/desactivar individuos
map <- map %>%
  addLayersControl(
    overlayGroups = grupos,  # Usa los birdID como grupos de control
    options = layersControlOptions(collapsed = FALSE)  # Mostrar la lista expandida
  )

# Guardar el mapa como archivo HTML
saveWidget(map, file = "docs/index.html", selfcontained = FALSE)
