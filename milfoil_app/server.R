#create server object (custom function)

server <- shinyServer(
  function(input, output, session){
    #all operations server will actually do
    

# Strain Map --------------------------------------------------------------

    
output$milfoil_map <- renderLeaflet({

  leaflet(options = list(minZoom = 4.5, maxZoom = 14)) %>%
    setMaxBounds(lng1 = bounds[1]-10 ,lat1 = bounds[2]-10, lng2 = bounds[3]+10, lat2 = bounds[4]+10) %>%
    addTiles() %>%
    addPolygons(
      data = US$geometry,
      stroke = TRUE,
      weight = 2,
      fill = FALSE,
      color = "black"
    ) %>%
    addCircleMarkers(
     data = MSU_db_markersSF$geometry,
     radius = 5,
     color = "#555D80",
    fillColor = "#94A4DF",
  popup = lapply(MSU_db_markers$maplabels, HTML),
  popupOptions = popupOptions(
    className = "map_hovers"))
    
})    



# Reactive Values ---------------------------------------------------------
#
Our_reactives = reactiveValues(current_df = MSU_db_markers)





# All Observers ---------------------------------------------------------------

# Filter Observers --------------------------------------------------------

#OBSERVER TO WATCH FILTERS AND FILTER OUR REACTIVE DATAFRAME ACCORDINGLY
observeEvent(list(input$Filter_States, 
                  input$Filter_Counties, 
                  input$Filter_Lakes,
                  input$Filter_SubBasins,
                  input$Filter_WBID,
                  input$Filter_Taxon,
                  input$Filter_Strain), priority = 2, {
  
#SHORT HANDS                    
  state = input$Filter_States 
  county = input$Filter_Counties
  lake = input$Filter_Lakes
  sub = input$Filter_SubBasins
  WBID = input$Filter_WBID
  taxon = input$Filter_Taxon
  strain = input$Filter_Strain
  
  if(!"All" %in% state &
     !"All" %in% county &
     !"All" %in% lake) {
    df_to_filter = MSU_db_markers_sb
  } else {
    df_to_filter = MSU_db_markers
  }
 
   
#TEXT THAT JUST LIVES IN THE DIV BELOW THE FILTERS DIV  
  output$general_info = renderText({
    HTML("<h2 id = 'info_header'>Strain Nomenclature</h2>
<p><span id=arrowtag>&#x2794 </span>The first letter in the strain ID referrers to the taxon, distinguishing between Eurasian (<i>Myriophyllum spicatum</i>), northern (<i>M. sibiricum</i>) or hybrid (<i>M. spicatum × M. sibiricum</i>) watermilfoil.</p>
<p><span id=arrowtag>&#x2794 </span>Additionally, ‘MISGP’ or ‘MYR’ in the ID represents the original database this sample is from, primarily for in-house purposes, but it is included for cross referencing convenience. </p>
<p><span id=arrowtag>&#x2794 </span>Lastly, the number at the end of the ID signifies the sample number it was initially assigned in the given database.</p>"
  )})  
  
  
#ESTABLISHING FOR EACH FILTER WHAT WE WILL FILTER BY (EITHER NOTHING OR SPECIFIC VALUES)  
  
  if("All" %in% state | is_null(state)) {
    states_to_filter_by = unname(state_codes)
    
  } else {
    states_to_filter_by = state
  }
  
  if("All" %in% county | is_null(county)) {
    counties_to_filter_by = unique(df_to_filter$County)
    
  } else {
    counties_to_filter_by = county
  }
  
  if("All" %in% lake | is_null(lake)) {
    lakes_to_filter_by = unique(df_to_filter$Lake)
    
  } else {
    lakes_to_filter_by = lake
  }
  
  if("All" %in% sub | is_null(sub)) {
    basins_to_filter_by = unique(df_to_filter$Lake_sub_basin)
    
  } else {
    basins_to_filter_by = sub
  }
  
  if("All" %in% taxon) {
    taxa_to_filter_by = unique(df_to_filter$Taxon)
    
  } else {
    taxa_to_filter_by = taxon
  }
  
  if("All" %in% strain | is_null(strain)) {
    strains_to_filter_by = "-"
    
  } else {
    strains_to_filter_by = as.character(strain)
  }
  

  
#THIS PART IS DOING THE FILTERING  
  Our_reactives$current_df = df_to_filter %>%
     filter(State %in% states_to_filter_by, 
            County %in% counties_to_filter_by,
            Lake %in% lakes_to_filter_by,
            Lake_sub_basin %in% basins_to_filter_by,
            Taxon %in% taxa_to_filter_by,
            grepl(strains_to_filter_by, .$Strains, fixed = T))
})


#THESE ARE DISABLING AND ENABLING FILTERS ACCORDING TO WHAT FILTERS THE USER HAS ALREADY USED
observeEvent(list(input$Filter_States, input$Filter_Counties, input$Filter_Lakes), priority = -1, { 
  if(!"All" %in% input$Filter_States & !"All" %in% input$Filter_Counties) {
    shinyjs::disable("Filter_States")
    
  } else {
    shinyjs::enable("Filter_States")
  }
})


observeEvent(list(input$Filter_States, input$Filter_Counties, input$Filter_Lakes), priority = 0, {
  if(!"All" %in% input$Filter_Lakes) {
    shinyjs::disable("Filter_States")
    shinyjs::disable("Filter_Counties")
    
  } else {
    shinyjs::enable("Filter_States")
    shinyjs::enable("Filter_Counties")
  }
})



#WATCHING THE STATES FILTER AND POPULATING THE COUNTIES FILTER ACCORDING TO THE COUNTIES THAT EXIST WITHIN THAT STATE
observeEvent(input$Filter_States, priority = -1, {
  
  updateSelectInput(session, 
                    "Filter_Counties",
                    choices = c("All", sort(unique(Our_reactives$current_df$County))),
                    selected = c("All" = "All"))
})

#WATCHING THE STATES AND COUNTIES FILTER AND POPULATING THE LAKES FILTER ACCORDING THE THE STATE AND OR COUNTY SELECTED
#AND SHOWING OR HIDING THE LAKE FILTER DEPENDING ON USER FILTER SELECTION
observeEvent(list(input$Filter_States, input$Filter_Counties), {
  if(!"All" %in% input$Filter_States | !"All" %in% input$Filter_Counties) {
    updateSelectInput(session, 
                      "Filter_Lakes",
                      choices = c("All", sort(unique(Our_reactives$current_df$Lake))),
                      selected = "All")
    show("Filter_Lakes")
    
  } else{
    hide("Filter_Lakes")
  }
  
})


#WATCHING THE STATES, COUNTIES AND LAKES FILTER, POPULATING THE SUB BASIN FILTER ACCORDING THE THE STATE, COUNTY AND OR LAKE SELECTED
#AND SHOWING OR HIDING THE SUB BASIN FILTER DEPENDING ON USER FILTER SELECTION
observeEvent(list(input$Filter_States, input$Filter_Counties, input$Filter_Lakes), {
  if(!"All" %in% input$Filter_States & !"All" %in% input$Filter_Counties & !"All" %in% input$Filter_Lakes) {
    updateSelectInput(session, 
                      "Filter_SubBasins",
                      choices = c("All", sort(unique(Our_reactives$current_df$Lake_sub_basin))),
                      selected = "All")
    show("Filter_SubBasins")
    
  } else{
    hide("Filter_SubBasins")
  }
  
})

#browser()

#THIS IS WATCHING TO SEE IF THE REACTIVE DF HAS CHANGED BASED ON FILTERS THAT HAVE CHANGED AND IF SO IT FLYS TO THE CURRENT SELECTIONS
observe({
  req(input$Filter_Lakes) #This make a smoother transition between lake selections so it doesn't zoom all the way back out to the state level
  Our_df_SF = st_as_sf(
    Our_reactives$current_df,
    coords = c("Lake_long", "Lake_lat"),
    crs = 4326  # WGS 84 CRS (standard for lat/long)
  )
  
  bounds <- unname(st_bbox(Our_df_SF))
  
  leafletProxy("milfoil_map")%>%
    flyToBounds(bounds[1], bounds[2], bounds[3], bounds[4])# %>%
    # setMaxBounds(bounds[1], bounds[2], bounds[3], bounds[4])
})



# Reactive dataframe observer ---------------------------------------------


#REFRESHES MAP MARKERS BASED ON HOW OUR MAP SELECTIONS HAVE CHANGED
observeEvent(Our_reactives$current_df, priority = 2, {
  
  Our_df_SF = st_as_sf(
    Our_reactives$current_df,
    coords = c("Lake_long", "Lake_lat"),
    crs = 4326  # WGS 84 CRS (standard for lat/long)
  )
  
#  browser() #allows us to temporarily look at what the df looks like at that moment and help with debugging WE DO NOT WANT THIS TO RUN ALL THE TIME
  
  leafletProxy("milfoil_map") %>%
    clearMarkers() %>%
    addCircleMarkers(
      data = Our_df_SF$geometry,
      radius = 7.5,
      color = 'black',
      stroke = T,
      opacity = 1,
      weight = 1,
      fillColor = '#94A4DF',
      fillOpacity = .7,
      popup = lapply(Our_reactives$current_df$maplabels, HTML),
      popupOptions = popupOptions(
        className = "map_hovers")) 
  
}) 



# Button observers --------------------------------------------------------


#MAKING THE POP UP INFO BOX
observeEvent(list(session$initialized, input$info_button),{
  show_alert(title = "How To Use This Map", closeOnClickOutside = FALSE, showCloseButton = TRUE, html = TRUE,
              text = HTML("
<p> On this web page, you will find a map of the lower 48 states in the US at the center. Circle markers on the map show watermilfoil strains present within a given lake. When you click on any marker, a pop-up appears, revealing additional information about the selected strain such as its location and herbicide response data.</p>

<p>To refine your search, filters are available at the left of the screen. These filters enable you to narrow down your results by state, county, lake, waterbody ID and taxa. Moreover, you can filter by an individual strain of interest, making it easier to identify its occurrences in other locations. Next to each filter there is an information button that can tell you how to use the respective filter. </p>

<p>Clicking on any of the purple circle markers on the map will trigger a pop-up box that provides comprehensive information about the corresponding lake. This information encompasses the state, county, lake name, waterbody ID, and the specific strain(s) present within the lake. For strains with available herbicide response data, a clickable button is provided within the pop-up box. This button, when clicked, will display further details regarding the strain's response to tested herbicides. This supplementary information will be displayed below the filters, positioned to the left of the map. Alongside the strain's herbicide response data, relevant citations are also incorporated for reference.</p>

<p>It’s important to note that only a fraction of the lakes in the United States have been genetically surveyed, with a greater concentration of surveying in the Midwest, due to funding and collaborative projects. As a result, certain strains or taxa may be present in more lakes than shown on this map. If your lake isn’t represented, and you’re curious about the watermilfoil strains present there, please don’t hesitate to contact us or visit the <a href = 'https://www.montana.edu/thumlab/'> Thum Lab’s website </a> for more information!</p>

<p>Lastly, if you want a refresher of any of this information, please click on the <b>Map Instructions</b> button to reopen this pop-up.</p>

"))
})


#MAKING FILTER INFO BOXES
observeEvent(list(session$initialized, input$info_button),{
  show_alert
})



#THIS IS THE BUTTON FOR HERBICIDE RESPONSE
observeEvent(input$responseClicked, {

  strain_herb = str_split_1(pattern = "-", 
              string = input$responseClicked)
  
  which_row = which(herb_table$Microsat_ID == strain_herb[1])
  if(strain_herb[2] == "Fluridone") {
    which_col = "Fluridone_response"
  } else {
    which_col = "X2_4D_response"
  }
  
  output$general_info = renderText({
    herb_table[which_row, which_col]
  })
  
})


#THIS IS TEXT THAT FILLS THE INFO DIV


observeEvent(list(session$initialized),{

output$general_info = renderText(({
  HTML("<h2 id = 'info_header'>Strain Nomenclature</h2>
<p><span id=arrowtag>&#x2794 </span>The first letter in the strain ID referrers to the taxon, distinguishing between Eurasian (<i>Myriophyllum spicatum</i>), northern (<i>M. sibiricum</i>) or hybrid (<i>M. spicatum × M. sibiricum</i>) watermilfoil.</p>
<p><span id=arrowtag>&#x2794 </span>Additionally, ‘MISGP’ or ‘MYR’ in the ID represents the original database this sample is from, primarily for in-house purposes, but it is included for cross referencing convenience. </p>
<p><span id=arrowtag>&#x2794 </span>Lastly, the number at the end of the ID signifies the sample number it was initially assigned in the given database.</p>
<p><span id=arrowtag>&#x2794 </span>Currently, we do not actively track northern watermilfoil strains due to the presence of numerous strains, most of which are not a priority for management becuase they are a native to the United States. As a result, our list of strains may include a combination of northern watermilfoil samples identified using our the same strain nomenclature mentioned above. Some strains may be marked as 'N-REF' followed by their assigned sample number, while others may be labeled simply as 'NORTHERN'.</p>
")
}))})


#LIST OF LAKES BUTTON
observeEvent(input$lake_button, {
  lake_list = sort(unique(Our_reactives$current_df$Lake_WBI))
  lake_list2 = paste(lake_list, collapse = ",<br>")
  show_alert(title = "How To Use This Map", closeOnClickOutside = FALSE, showCloseButton = TRUE, html = TRUE,
             text = HTML(lake_list2))
})



#CLEAR FILTERS BUTTON
observeEvent(input$reset_button,{
  updateSelectInput(session, "Filter_States", selected = "All")
  updateSelectInput(session, "Filter_Counties", selected = "All")
  updateSelectInput(session, "Filter_Lakes", selected = "All")
  updateSelectInput(session, "Filter_Strain", selected = "All")
  updateSelectInput(session, "Filter_Taxon", selected = "All")
  updateSelectInput(session, "Filter_SubBasins", selected = "All")
})


#putting logos in
output$combined_logos = renderImage({
  list(src = "www/combined logos.png")
}, deleteFile = F)


output$milfoilimg1 = renderImage({
  list(src = "www/milf_art.png")
}, deleteFile = F)

output$milfoilimg2 = renderImage({
  list(src = "www/milf_art.png")
}, deleteFile = F)

output$milfoilimg3 = renderImage({
  list(src = "www/milf_art.png")
}, deleteFile = F)

output$milfoilimg4 = renderImage({
  list(src = "www/milf_art.png")
}, deleteFile = F)



}) #END OF SERVER OBJECT, DON'T MOVE!!!!!!!

