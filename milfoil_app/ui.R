ui <-   div(id = "entirepage",
  
  tags$head(tags$link(
    rel = "stylesheet", 
    type = "text/css",
    href = "stylist.css"
  )),
  # 
  # tags$head(tags$script(HTML('
  #                           $(function () { 
  #       $("[data-toggle=tooltip]").tooltip();   
  #     });'))),
  
  tags$head(HTML('<meta name="viewport" content="width=device-width, initial-scale=1.0">')),
  
#Javascript code that puts a click event on the buttons and then passes the info about that to shiny's input object using Shiny.onInputChange
#specifically, it passes the "ID" of the button which is just the strain that was associated with that button 
  tags$script(
    '
  $(document).on("click", ".response-button", function() {
    var buttonId = $(this).data("id");
    Shiny.onInputChange("responseClicked", buttonId);
  });
  '
  ),

tags$head(
  tags$script('
      // Check if the browser is Safari
      if (navigator.vendor & navigator.vendor.includes("Apple")) {
        document.documentElement.classList.add("safari");
      }
    ')
),
  
#LETS US PERFORM JAVASCRIPT IN SHINY
useShinyjs(),
 
  
#DIVIDE THIS PAGE LEVEL DIV INTO 2 ROWS

  
    div(id = "toprow", class= "safari-divs",
        
        div(id = "topleftbuffer",
            
            imageOutput("milfoilimg1")
            
            ),
        div(id = "titleandlogos",
            
            div(id="title",
                
              span(HTML("<h1 id ='apptitle'>MilfoilMapper</h1>"))
                
             ),
            div(id="logos",
                
                imageOutput("combined_logos")
                
                )
            
            ),
        div(id = "toprightbuffer",
            
            imageOutput("milfoilimg2")
            
            )
        
        ), #End top row
    
    div(id = "middlerow",
        
        div(id = "filtersandinfo",
            
            div(id = "filters",
                
                actionButton("info_button",
                             "Map Instructions"),   
                
                selectInput("Filter_States", #inputID argument
                            div(id = "state_picker", 
                                HTML(paste("Pick a State", "<span style='color:#B3B7C9; font-size:12pt'><i>(Delete 'All' First)</i></span>"))), #label argument
                            choices = state_codes,
                            selectize = TRUE,
                            multiple = TRUE,
                            selected = c("All" = "All")), 
                
                selectInput("Filter_Counties", #inputID argument
                            div(id = "county_picker",  
                                HTML(paste("Pick A County", "<span style='color:#B3B7C9; font-size:12pt'><i>(Delete 'All' First)</i></span>"))),
                            c("All" = "All", sort(unique(MSU_db_markers$County))), #choices argument
                            multiple = TRUE,
                            selected = c("All" = "All")),
                
                hidden(selectInput("Filter_Lakes",
                                   div(id = "lake_picker",  
                                       HTML(paste("Pick A Lake", "<span style='color:#B3B7C9; font-size:12pt'><i>(Delete 'All' First)</i></span>"))),
                                   choices = c("All" = "All"),
                                   multiple = TRUE,
                                   selected = c("All" = "All"))),
                
                hidden(selectInput("Filter_SubBasins",
                                   div(id = "sub_basin_picker",  
                                       HTML(paste("Pick A Known Sub Basin", "<span style='color:#B3B7C9; font-size:12pt'><i>(Delete 'All' First)</i></span>"))),
                                   choices = c("All" = "All"),
                                   multiple = TRUE,
                                   selected = c("All" = "All"))),
                
                selectInput("Filter_Taxon",
                            div(id = "taxon_picker", 
                                HTML(paste("Pick A Known Taxon", "<span style='color:#B3B7C9; font-size:12pt'><i>(Delete 'All' First)</i></span>"))),
                            choices = c("All" = "All", sort(unique(MSU_db_markers$Taxon))),
                            multiple = TRUE,
                            selected = c("All" = "All")),
                
                selectInput("Filter_Strain",
                            div(id = "strain_picker",  
                                HTML(paste("Pick A Known Strain", "<span style='color:#B3B7C9; font-size:12pt'><i>(Delete 'All' First)</i></span>"))),
                            choices = c("All" = "All", sort(unique(MSU_database$Microsatellite_strain))),
                            multiple = TRUE,
                            selected = c("All" = "All")),
               
                #LIST OF LAKES
                div(id="lakelistbutton",
                    
                    actionButton("lake_button",
                                 "List of Lakes")),
                
                #CLEAR ALL FILTER BUTTONS     
                div(id="floatbutton", 
                    
                    actionButton("reset_button",
                             "Clear Filters")
                  )
                ),
            #GENERAL INFO DIV WHERE NOMENCLATURE LIVES AND HERBICIDE RESPONSE POPS UP
            div(id = "info",
                
                htmlOutput("general_info"),
            
            )
            ),
        #MAP DIV
        div(id = "map",
            
            leafletOutput("milfoil_map", height = "96%")
            
            )
        
        ), #End middle row
    
    div(id= "bottomrow",
        
        div(id = "bottomleftbuffer",
            
            imageOutput("milfoilimg3")
            
            ),
        #FOOTER DIV
        div(id = "footer",
            
            htmlOutput("suggestions"),
            
            ),
        
        div(id = "bottomrightbuffer",
            
            imageOutput("milfoilimg4")
            
            )
        
        )
    
) #END OF PAGE

