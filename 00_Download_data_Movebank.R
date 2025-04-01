
library(pacman)
pacman::p_load("dplyr", "lubridate", "move", "leaflet", "htmlwidgets", "jsonlite")

user <- Sys.getenv("MOVEBANK_USER")
password <- Sys.getenv("MOVEBANK_PASS")

# Log in
loginStored <- movebankLogin(username=user, password = password)
# Storing the study name
st <- "AMPLIAMAR (Manx shearwaters)"
# Storing the names of the individuals
animals <- c("5020551", "5102431", "5102432", "5102433", "5102434", "5102435")

Animal_Data <- getMovebankAnimals(study= st,
                                  login=loginStored)
Animal_Names <- as.character(unique(Animal_Data$animalName))

gps  <- getMovebankData(study = st, 
                        login = loginStored, 
                        removeDuplicatedTimestamps = TRUE,
                        animalName = Animal_Names)


gps.df <- data.frame(
  birdID = gsub("^X", "", gps@trackId),
  tagID = gps@data$tag_local_identifier,
  datetimeGMT = gps@data$timestamp,
  latitude = gps@data$location_lat,
  longitude = gps@data$location_long
)

gps.df$sex <- gps@idData$sex[match(gps.df$birdID, gps@idData$ring_id)]

gps.df$sex <- ifelse(gps.df$sex == 'f', 'Hembra', 'Desconocido')

head(gps.df)

# Guardar en CSV
write.csv(gps.df, "gps_data.csv", row.names = FALSE)

# Guardar en JSON
write_json(gps.df, "gps_data.json", pretty = TRUE)
