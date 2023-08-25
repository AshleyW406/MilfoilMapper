#CALLING AND LOADING ALL OF OUR NECESSARY PACKAGES
library(shiny)
library(tidyverse) #maybe get rid of this eventually, maybe overkill
library(leaflet)
library(USAboundaries)
library(sf)
library(waiter)
library(shinyjs)
library(shinyWidgets)
library(readr)
library(shinyBS)


#install.packages("USAboundariesData", repos = "https://ropensci.r-universe.dev", type = "source")
#install.packages("USAboundaries", repos = "https://ropensci.r-universe.dev", type = "source")


# Loading in the database -------------------------------------------------


MSU_database <- read.csv("Final_2023_MSU_Database_ALW.csv")
MSU_database <- MSU_database[,0:29]

MSU_database$Lake_lat <- as.numeric(MSU_database$Lake_lat)
MSU_database$Lake_long <- as.numeric(MSU_database$Lake_long)
MSU_database$Number <- as.numeric(MSU_database$Number)
MSU_database$Date_collected <- as.Date(MSU_database$Date_collected)

MSU_database = MSU_database %>% 
  filter(!is.na(Lake_long), !is.na(Lake_lat), Lake_long > -180, Lake_long < 0)


# Filtering the database df -----------------------------------------------

#FILTERING EVERYTHING OUT THAT WE DON'T WANT TO SHOW ON THE MAP
MSU_database = MSU_database %>%
  filter(!is.na(Microsatellite_strain), Microsatellite_strain != "FAIL")%>%
  mutate(Taxon = case_when(
    startsWith(Microsatellite_strain, "E") ~ "Eurasian",
    startsWith(Microsatellite_strain, "H") ~ "Hybrid",
    startsWith(Microsatellite_strain, "N") ~ "Northern")) %>%
  relocate(Taxon, .after = Collector)




#MADE A NEW COLUMN CALLED STRAIN RESPONSE
MSU_database = MSU_database %>% 
  mutate(strain_response = paste0("<span id=arrowtag>&#x2794 </span>", Microsatellite_strain, " (2,4-D: " , 
                                  str_to_title(X2_4D_response), 
                                  "; Fluridone: ", 
                                  str_to_title(Fluridone_response), 
                                  ")" ))




#A FOR LOOP CREATING AND POPULATING THE RESISTANT AND SENSITIVE BUTTONS

for(i in 1:nrow(MSU_database)) {
  
  MSU_database$strain_response[i] = gsub(pattern = "2,4-D: Sensitive",
                                         replacement = paste0("2,4-D: ",
                                                              "<button class = 'response-button' data-id = '",
                                                              MSU_database$Microsatellite_strain[i], "-2,4-D", 
                                                              "'><span class = 'color_green'>Sensitive</span></button>"), 
                                         x = MSU_database$strain_response[i])
  
  MSU_database$strain_response[i] = gsub(pattern = "2,4-D: Resistant",
                                         replacement = paste0("2,4-D: ",
                                                              "<button class = 'response-button' data-id = '",
                                                              MSU_database$Microsatellite_strain[i], "-2,4-D",
                                                              "'><span class = 'color_pink'>Resistant</span></button>"), 
                                         x = MSU_database$strain_response[i])
  
  MSU_database$strain_response[i] = gsub(pattern = "Fluridone: Sensitive",
                                         replacement = paste0("Fluridone: ",
                                                              "<button class = 'response-button' data-id = '",
                                                              MSU_database$Microsatellite_strain[i], "-Fluridone", 
                                                              "'><span class = 'color_green'>Sensitive</span></button>"), 
                                         x = MSU_database$strain_response[i])
  
  MSU_database$strain_response[i] = gsub(pattern = "Fluridone: Resistant",
                                         replacement = paste0("Fluridone: ",
                                                              "<button class = 'response-button' data-id = '",
                                                              MSU_database$Microsatellite_strain[i], "-Fluridone",
                                                              "'><span class = 'color_pink'>Resistant</span></button>"), 
                                         x = MSU_database$strain_response[i])
  
}



#CREATING THE MSU_DB_MARKERS DF
MSU_db_markers = MSU_database %>%
  filter(Microsatellite_strain != "FAIL") %>%
  group_by(Lake) %>%
  summarize(Lake_sub_basin = first(Lake_sub_basin),
            Waterbody_ID = first(Waterbody_ID),
            State = first(State),
            County = first(County),
            Taxon = first(Taxon),
            Lake_lat = first(Lake_lat),
            Lake_long = first(Lake_long),
            Strains = paste0(unique(strain_response), collapse = ",<br>")) %>% 
  ungroup()


#LOADING IN THE HERBICIDE RESPONSE TABLE
herb_table <- read.csv("Herbicide_response_table.csv")

#CREATING A STATE_CODES OBJECT THAT HAS FULL STATE NAMES AND THEIR ABBREVIATIONS
state_codes <- c("All" = "All", "Alabama" = "AL", "Arizona" = "AZ", "Arkansas" = "AR", "California" = "CA",
                 "Colorado" = "CO", "Connecticut" = "CT", "Delaware" = "DE", "Florida" = "FL", "Georgia" = "GA",
                 "Idaho" = "ID", "Illinois" = "IL", "Indiana" = "IN", "Iowa" = "IA", "Kansas" = "KS", "Maine" = "ME",
                 "Maryland" = "MD", "Massachusetts" = "MA", "Michigan" = "MI", "Minnesota" = "MN", 
                 "Mississippi" = "MS", "Montana" = "MT", "Nebraska" = "NE", "Nevada" = "NV", "New Hampshire" = "NH",
                 "New Jersy" = "NJ", "New Mexico" = "NM", "New York" = "NY", "North Carolina" = "NC",
                 "North Dakota" = "ND", "Oregon" = "OR", "Pennsylvania" = "PA", "Rhode Island" = "RI", 
                 "South Carolina" = "SC", "South Dakota" = "SD", "Tennessee" = "TN", "Texas" = "TX", "Utah" = "UT",
                 "Vermont" = "VT", "Virginia" = "VA", "Washington" = "WA", "West Virginia" = "WV", 
                 "Wisconsin" = "WI", "Wyoming" = "WY")


#SUBSETS THE MAP TO JUST SHOW THE LOWER 48 STATES
US <- subset(USAboundaries::us_states(),! USAboundaries::us_states()$name %in% c("Alaska", "Puerto Rico", "Hawaii")) 




#TAKING THE SF PACKAGE AND GIVING OUR DF A GEOMETRY COLUMN
MSU_db_markersSF = st_as_sf(
  MSU_db_markers,
  coords = c("Lake_long", "Lake_lat"),
  crs = 4326  # WGS 84 CRS (standard for lat/long)
)

bounds <- unname(st_bbox(MSU_db_markersSF))




# Buttons and pop ups -----------------------------------------------------



MSU_db_markers$Lake_WBI = unlist(lapply(seq(1, nrow(MSU_db_markers)), function (x){
  paste0(MSU_db_markers$Lake[x], 
         " (",
         MSU_db_markers$Waterbody_ID[x],
         ")")
}))



#THIS FUNCTION ADDS LABELS TO EACH POINT WHEN CLICKED ON

MSU_db_markers$maplabels = lapply(seq(1, nrow(MSU_db_markers)),
                                    function(i) {
                                      paste0("<span class = 'bold_this'> State: </span>", MSU_db_markers[i, "State"], '<br>',
                                             "<span class = 'bold_this'> County: </span>", MSU_db_markers[i, "County"], '<br>',
                                             "<span class = 'bold_this'> Lake (Waterbody ID): </span>", str_to_title(MSU_db_markers[i, "Lake_WBI"]), '<br>',
                                             "<span class = 'bold_this'> Sub Basin: </span>", MSU_db_markers[i, "Lake_sub_basin"], '<br>',
                                             "<span class = 'bold_this'> Strain IDs</span> (Herbicide Response): <br>", MSU_db_markers[i, "Strains"], '<br>'
                                             )
                                    })



#CREATING THE MSU_DB_MARKERS_SB DF
MSU_db_markers_sb = MSU_database %>%
  filter(Microsatellite_strain != "FAIL") %>%
  group_by(Lake, Lake_sub_basin) %>%
  summarize(Lake_sub_basin = first(Lake_sub_basin),
            Waterbody_ID = first(Waterbody_ID),
            State = first(State),
            County = first(County),
            Taxon = first(Taxon),
            Lake_lat = first(Lake_lat),
            Lake_long = first(Lake_long),
            Strains = paste0(unique(strain_response), collapse = ",<br>")) %>% 
  ungroup()



#TAKING THE SF PACKAGE AND GIVING OUR DF A GEOMETRY COLUMN
MSU_db_markersSF_sb = st_as_sf(
  MSU_db_markers_sb,
  coords = c("Lake_long", "Lake_lat"),
  crs = 4326  # WGS 84 CRS (standard for lat/long)
)

bounds_sb <- unname(st_bbox(MSU_db_markersSF_sb))



#MAKING LAKE AND WBID INTO THE SAME COLUMN
MSU_db_markers_sb$Lake_WBI = unlist(lapply(seq(1, nrow(MSU_db_markers_sb)), function (x){
  paste0(MSU_db_markers_sb$Lake[x], 
         " (",
         MSU_db_markers_sb$Waterbody_ID[x],
         ")")
}))



MSU_db_markers_sb$maplabels = lapply(seq(1, nrow(MSU_db_markers_sb)),
                                  function(i) {
                                    paste0("<span class = 'bold_this'> State: </span>", MSU_db_markers_sb[i, "State"], '<br>',
                                           "<span class = 'bold_this'> County: </span>", MSU_db_markers_sb[i, "County"], '<br>',
                                           "<span class = 'bold_this'> Lake (Waterbody ID): </span>", str_to_title(MSU_db_markers_sb[i, "Lake_WBI"]), '<br>',
                                           "<span class = 'bold_this'> Sub Basin: </span>", MSU_db_markers_sb[i, "Lake_sub_basin"], '<br>',
                                           "<span class = 'bold_this'> Strain IDs</span> (Herbicide Response): <br>", MSU_db_markers_sb[i, "Strains"], '<br>'
                                    )
                                  })



