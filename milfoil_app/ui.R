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
      if (navigator.vendor && navigator.vendor.includes("Apple")) {
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
                            div("Pick A State"), #label argument
                            choices = state_codes,
                            selectize = TRUE,
                            multiple = TRUE,
                            selected = c("All" = "All")), 
                
                selectInput("Filter_Counties", #inputID argument
                            div("Pick A County"),
                            c("All" = "All", sort(unique(MSU_db_markers$County))), #choices argument
                            multiple = TRUE,
                            selected = c("All" = "All")),
                
                hidden(selectInput("Filter_Lakes",
                                   div("Pick A Lake"),
                                   choices = c("All" = "All"),
                                   multiple = TRUE,
                                   selected = c("All" = "All"))),
                
                hidden(selectInput("Filter_SubBasins",
                                   div("Pick A Known Sub Basin"),
                                   choices = c("All" = "All"),
                                   multiple = TRUE,
                                   selected = c("All" = "All"))),
                
                selectInput("Filter_Taxon",
                            div("Pick A Known Taxon"),
                            choices = c("All" = "All", sort(unique(MSU_db_markers$Taxon))),
                            multiple = TRUE,
                            selected = c("All" = "All")),
                
                selectInput("Filter_Strain",
                            div("Pick A Known Strain"),
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
            
            HTML("<p>Questions, suggestions or bugs? Please email them to Ashley at <a href = 'mailto:ashley.wolfe3@montana.edu'>ashley.wolfe3@montana.edu</a>.<br>The data on this website was last updated 7/1/2023.</p>")
            
            ),
        
        div(id = "bottomrightbuffer",
            
            imageOutput("milfoilimg4")
            
            )
        
        )
    
) #END OF PAGE

