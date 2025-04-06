library(leaflet)
library(dplyr)
library(htmlwidgets)

# Buscar el archivo gps_data_ más reciente
gps_files <- list.files(pattern = "gps_data_\\d+.*\\.csv")
latest_file <- gps_files[which.max(file.info(gps_files)$mtime)]

# Leer el archivo más reciente
gps.df <- read.csv(latest_file)

# Convertir la columna de fecha a formato adecuado
gps.df$datetimeGMT <- as.POSIXct(gps.df$datetimeGMT, format = "%Y-%m-%d %H:%M:%S", tz = "GMT")

# Filtrar datos de los últimos 2 días
lst_days <- as.POSIXct(Sys.time(), tz = "GMT") - (2 * 24 * 60 * 60)
gps.df2 <- gps.df %>% filter(datetimeGMT >= lst_days)

# Validar que haya datos
if (nrow(gps.df2) == 0 || all(is.na(gps.df2$datetimeGMT))) {
  stop("No hay datos en gps.df2 o solo contiene NA.")
}

# Crear paleta de colores
pal.colors <- colorFactor(palette = "Set1", domain = gps.df$birdID)

# Crear el mapa base
imap <- leaflet(options = leafletOptions(preferCanvas = TRUE)) %>%
  addTiles(options = tileOptions(maxZoom = 10))

# Obtener timestamp único para usar en todo
timestamp <- format(Sys.time(), "%Y%m%d_%H%M", tz = "GMT", usetz = TRUE)

# Agregar tracks y marcadores
grupos <- unique(gps.df$birdID)
for (bird in grupos) {
  gps.ind <- gps.df2 %>% filter(birdID == bird)

  lst_pos <- gps.ind %>% filter(datetimeGMT == max(datetimeGMT, na.rm = TRUE))

  imap <- imap %>%
    addPolylines(
      lng = ~longitude, lat = ~latitude,
      data = gps.ind,
      color = 'darkgrey',
      weight = 0.75, opacity = 0.7,
      group = bird
    ) %>%
    addCircleMarkers(
      lng = ~longitude, lat = ~latitude,
      data = gps.ind,
      radius = 0.5,
      color = ~pal.colors(birdID),
      popup = ~paste("ID:", birdID, "<br>Date:", datetimeGMT, "Sex:", sex),
      group = bird
    ) %>%
    addAwesomeMarkers(
      lng = ~longitude, lat = ~latitude,
      data = lst_pos,
      icon = awesomeIcons(icon = 'star', library = 'fa', markerColor = 'red'),
      popup = ~paste("ID:", birdID, "<br>Date:", datetimeGMT, "Sex:", sex),
      group = bird
    )
}

# Agregar timestamp visual en el mapa como etiqueta
imap <- imap %>%
  addLabelOnlyMarkers(
    lng = min(gps.df2$longitude, na.rm = TRUE),
    lat = max(gps.df2$latitude, na.rm = TRUE),
    label = paste("🕒", timestamp, "GMT"),
    labelOptions = labelOptions(
      noHide = TRUE,
      direction = 'right',
      textOnly = TRUE,
      style = list(
        "color" = "black",
        "font-size" = "12px",
        "background-color" = "white",
        "padding" = "5px",
        "border-radius" = "5px"
      )
    )
  )

# Añadir también una caja con timestamp en la esquina
imap <- imap %>%
  addControl(
    html = paste0(
      "<div style='background: white; padding: 5px; border-radius: 5px;'>",
      "🕒 Última actualización: ", timestamp, " GMT</div>"
    ),
    position = "topright"
  )

# Preparar guardado del mapa
if (file.exists("docs/index.html")) file.remove("docs/index.html")
if (dir.exists("docs/index_files")) unlink("docs/index_files", recursive = TRUE)
if (!dir.exists("docs")) dir.create("docs")

# Guardar como index_TIMESTAMP.html
html_file <- paste0("docs/index_", timestamp, ".html")
saveWidget(imap, file = html_file, selfcontained = FALSE)

# Renombrar como index.html
file.copy(html_file, "docs/index.html", overwrite = TRUE)

# Añadir comentario al final del HTML
cat(sprintf("\n<!-- Última actualización: %s -->\n", timestamp),
    file = "docs/index.html", append = TRUE)


