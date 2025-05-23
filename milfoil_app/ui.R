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
# 
# tags$head(
#   tags$script('
#       // Check if the browser is Safari
#       if (navigator.vendor && navigator.vendor.includes("Apple")) {
#         document.documentElement.classList.add("safari");
#       }
#     ')
# ),

tags$head(
  tags$script(src = "move_logos.js")
),

##UI Code--make sure this goes somewhere inside of your largest UI container!

#We need to put this code inside two script HTML elements inside of our app's head element. This is how we do that. 
shiny::tags$head(
  shiny::tags$script(
    src = "https://www.googletagmanager.com/gtag/js?id=[Your specific Gtag]",
    async = ""
  ),
  shiny::tags$script( #Pure JavaScrit code below! No need to know what it's doing.
    src = "$(() => {

  /* Default installation */

  window.dataLayer = window.dataLayer || [];
  function gtag() {
    dataLayer.push(arguments);
  };
  gtag('js', new Date());
  gtag('config', '[G-T1T64RRSX3]');

});"
  )
),

#LET US PERFORM JAVASCRIPT IN SHINY
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
                                tags$span("Pick a State "), 
                                     tags$div("(Delete 'All' First)", class='label_span')), 
                            choices = state_codes,
                            selectize = TRUE,
                            multiple = TRUE,
                            selected = c("All" = "All")), 
                
                selectInput("Filter_Counties", #inputID argument
                            div(id = "county_picker",  
                                tags$span("Pick A County"),
                                    tags$div("(Delete 'All' First)", class='label_span')),
                            c("All" = "All", sort(unique(MSU_db_markers$County))), #choices argument
                            multiple = TRUE,
                            selected = c("All" = "All")),
                
                hidden(selectInput("Filter_Lakes",
                                   div(id = "lake_picker",  
                                       tags$span("Pick A Lake"),
                                            tags$div("(Delete 'All' First)", class='label_span')),
                                   choices = c("All" = "All"),
                                   multiple = TRUE,
                                   selected = c("All" = "All"))),
                
                hidden(selectInput("Filter_SubBasins",
                                   div(id = "sub_basin_picker",  
                                       tags$span("Pick A Sub Basin"),
                                            tags$div("(Delete 'All' First)", class='label_span')),
                                   choices = c("All" = "All"),
                                   multiple = TRUE,
                                   selected = c("All" = "All"))),
                
                selectInput("Filter_Taxon",
                            div(id = "taxon_picker", 
                                tags$span("Pick A Taxon"),
                                    tags$div("(Delete 'All' First)", class='label_span')),
                            choices = c("All" = "All", sort(unique(MSU_db_markers$Taxon))),
                            multiple = TRUE,
                            selected = c("All" = "All")),
                
                selectInput("Filter_Strain",
                            div(id = "strain_picker",  
                                tags$span("Pick A Strain"),
                                    tags$div("(Delete 'All' First)", class='label_span')),
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
            
            htmlOutput("suggestions")
            ),
        
        div(id = "bottomrightbuffer",
            
            imageOutput("milfoilimg4")
            
            )
        
        )

    
) #END OF PAGE

