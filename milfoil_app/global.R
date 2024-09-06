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
library(dplyr)
library(knitr)

#install.packages("USAboundariesData", repos = "https://ropensci.r-universe.dev", type = "source")
#install.packages("USAboundaries", repos = "https://ropensci.r-universe.dev", type = "source")

#make sure you run these lines of code before you try to publish the app (otherwise it won't work)
options(repos = c(
       ropensci = "https://ropensci.r-universe.dev",
       cran = "https://cran.rstudio.com/"
   ))
options("repos")


# Loading in the database -------------------------------------------------


MSU_database <- read.csv("Final_082624_MSU_Database.csv")
#this will need to change if I add more columns, only here to get rid of empty cols r is pulling in
MSU_database <- MSU_database[,0:30] 

MSU_database$Lake_lat <- as.numeric(MSU_database$Lake_lat)
MSU_database$Lake_long <- as.numeric(MSU_database$Lake_long)
MSU_database$Number <- as.numeric(MSU_database$Number)
MSU_database$Date_collected <- as.Date(MSU_database$Date_collected)

MSU_database = MSU_database %>% 
  filter(!is.na(Lake_long), !is.na(Lake_lat), Lake_long > -180, Lake_long < 0)

MSU_database[MSU_database == ""] = NA

# Filtering the database df -----------------------------------------------

#FILTERING EVERYTHING OUT THAT WE DON'T WANT TO SHOW ON THE MAP
MSU_database = MSU_database %>%
  filter(!is.na(Microsatellite_strain), Microsatellite_strain != "FAIL")%>%
  filter(Microsatellite_strain != "DIFFERENT SPECIES") %>%
  mutate(Taxon = case_when(
    startsWith(Microsatellite_strain, "E") ~ "Eurasian",
    startsWith(Microsatellite_strain, "H") ~ "Hybrid",
    startsWith(Microsatellite_strain, "N") ~ "Northern")) %>%
  relocate(Taxon, .after = Collector)

#HOW MANY LAKES DO WE HAVE?
#list(unique(MSU_database$Lake))

#HOW MANY UNIQUE STRAINS?
#list(unique(MSU_database$Microsatellite_strain))


# MAKING A TABLE TO SHOW ME NUMBER OF LAKES A STRAIN IS FOUND IN

lake_counts <- MSU_database %>%
  group_by(Microsatellite_strain, Lake_sub_basin) %>%
  summarise(Lakes_Found = n_distinct(Lake))

kable(lake_counts, 
      caption = "Number of Lakes Each Strain is Found in by State and County",
      col.names = c("Strain", "Lake_sub_basin", "Number of Lakes"))



#MADE A NEW COLUMN CALLED STRAIN RESPONSE
MSU_database = MSU_database %>% 
  mutate(strain_response = paste0("<span id=arrowtag>&#x2794 </span>", Microsatellite_strain, " (2,4-D: " , 
                                  str_to_title(X2_4D_response), 
                                  "; Fluridone: ", 
                                  str_to_title(Fluridone_response), 
                                  ")" ))
  


#A FOR LOOP CREATING AND POPULATING THE RESISTANT AND SENSITIVE BUTTONS

for(i in 1:nrow(MSU_database)) {
  
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
  
  
  MSU_database$strain_response[i] = gsub(pattern = "Fluridone: Of Concern",
                                         replacement = paste0("Fluridone: ",
                                                              "<button class = 'response-button' data-id = '",
                                                              MSU_database$Microsatellite_strain[i], "-Fluridone",
                                                              "'><span class = 'color_orange'>Of Concern</span></button>"), 
                                         x = MSU_database$strain_response[i])
  
  
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
  
  
}




#CREATING THE MSU_DB_MARKERS DF
MSU_db_markers = MSU_database %>%
  # filter(Microsatellite_strain != "FAIL") %>%
  # filter(Microsatellite_strain != "DIFFERENT SPECIES") %>%
  group_by(Lake_lat, Lake_long) %>%
  summarize(Lake = first(Lake),
            Lake_sub_basin = first(Lake_sub_basin),
            Waterbody_ID = first(Waterbody_ID),
            State = first(State),
            County = first(County),
            Year_collected = paste0(unique(Year_collected), collapse = ", "),
            Taxon = first(Taxon),
            Strains = paste0(unique(strain_response), collapse = ",<br>")) %>% 
  ungroup()



#LOADING IN THE HERBICIDE RESPONSE TABLE
herb_table <- read.csv("Herbicide_response_table.csv")

#CREATING A STATE_CODES OBJECT THAT HAS FULL STATE NAMES AND THEIR ABBREVIATIONS
state_codes <- c("All" = "All", "Illinois" = "IL", "Indiana" = "IN", "Iowa" = "IA", "Maryland" = "MD", "Michigan" = "MI", 
                 "Minnesota" = "MN", "Nebraska" = "NE", "New York" = "NY", "Ohio" = "OH",
                 "Pennsylvania" = "PA", "South Carolina" = "SC", "Vermont" = "VT", 
                 "Washington" = "WA",  "Wisconsin" = "WI")


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


#COMBINING LAKE AND WBID INTO ONE ROW
MSU_db_markers$Waterbody_ID[is.na(MSU_db_markers$Waterbody_ID)] = ""

MSU_db_markers$Lake_WBI = unlist(lapply(seq(1, nrow(MSU_db_markers)), function (x){
  paste0(MSU_db_markers$Lake[x],
         " (",
         MSU_db_markers$Waterbody_ID[x],
         ")")
}))



#GETTING RID OF (NA) IF THERE IS NOT WBID
for(r in 1:nrow(MSU_db_markers)) {
  MSU_db_markers$Lake_WBI[r] = gsub(pattern = "()", replacement = "", MSU_db_markers$Lake_WBI[r], fixed = TRUE)
}

#THIS FUNCTION ADDS LABELS TO EACH POINT WHEN CLICKED ON

MSU_db_markers$maplabels = lapply(seq(1, nrow(MSU_db_markers)),
                                  function(i) {
                                    paste0("<span class = 'bold_this'> State: </span>", MSU_db_markers[i, "State"], '<br>',
                                           "<span class = 'bold_this'> County: </span>", MSU_db_markers[i, "County"], '<br>',
                                           "<span class = 'bold_this'> Lake (Waterbody ID): </span>", str_to_title(MSU_db_markers[i, "Lake_WBI"]), '<br>',
                                           "<span class = 'bold_this'> Sub Basin: </span>", MSU_db_markers[i, "Lake_sub_basin"], '<br>',
                                           "<span class = 'bold_this'> Year(s) Collected: </span>", MSU_db_markers[i, "Year_collected"], '<br>',
                                           "<span class = 'bold_this'> Strain IDs</span> (Herbicide Response): <br>", MSU_db_markers[i, "Strains"], '<br>'
                                    )
                                   # if (!is.na(MSU_db_markers[i, "Lake_sub_basin"])) {
                                   #   paste0("<span class = 'bold_this'> Sub Basin: </span>", MSU_db_markers[i, "Lake_sub_basin"], '<br>')
                                   # }
                                  })



#CREATING THE MSU_DB_MARKERS_SB DF
MSU_db_markers_sb = MSU_database %>%
  group_by(Lake, Lake_sub_basin) %>%
  summarize(Lake_sub_basin = first(Lake_sub_basin),
            Waterbody_ID = first(Waterbody_ID),
            State = first(State),
            County = first(County),
            Taxon = first(Taxon),
            Lake_lat = first(Lake_lat),
            Lake_long = first(Lake_long),
            Year_collected = first(Year_collected),
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
MSU_db_markers_sb$Waterbody_ID[is.na(MSU_db_markers_sb$Waterbody_ID)] = ""

MSU_db_markers_sb$Lake_WBI = unlist(lapply(seq(1, nrow(MSU_db_markers_sb)), function (x){
  paste0(MSU_db_markers_sb$Lake[x],
         " (",
         MSU_db_markers_sb$Waterbody_ID[x],
         ")")
}))





#GETTING RID OF (NA) IF THERE IS NOT WBID
for(r in 1:nrow(MSU_db_markers_sb)) {
  MSU_db_markers_sb$Lake_WBI[r] = gsub(pattern = "()", replacement = "", MSU_db_markers_sb$Lake_WBI[r], fixed = TRUE)
}



MSU_db_markers_sb$maplabels = lapply(seq(1, nrow(MSU_db_markers_sb)),
                                  function(i) {
                                    paste0("<span class = 'bold_this'> State: </span>", MSU_db_markers_sb[i, "State"], '<br>',
                                           "<span class = 'bold_this'> County: </span>", MSU_db_markers_sb[i, "County"], '<br>',
                                           "<span class = 'bold_this'> Lake (Waterbody ID): </span>", str_to_title(MSU_db_markers_sb[i, "Lake_WBI"]), '<br>',
                                           "<span class = 'bold_this'> Sub Basin: </span>", MSU_db_markers_sb[i, "Lake_sub_basin"], '<br>',
                                           "<span class = 'bold_this'> Year(s) Collected: </span>", MSU_db_markers[i, "Year_collected"], '<br>',
                                           "<span class = 'bold_this'> Strain IDs</span> (Herbicide Response): <br>", MSU_db_markers_sb[i, "Strains"], '<br>'
                                    )
                                   # if (!is.na(MSU_db_markers_sb[i, "Lake_sub_basin"])) {
                                   #   paste0("<span class = 'bold_this'> Sub Basin: </span>", MSU_db_markers_sb[i, "Lake_sub_basin"], '<br>')
                                   # } 
                                  })



