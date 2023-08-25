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
  
  
#LETS US PERFORM JAVASCRIPT IN SHINY
useShinyjs(),
 
# 
# #We use a nice waiter to show while the App preloads, with a custom spinner, text, and logo, plus styling and a fadeout.
# useWaiter(), 
# waiter_preloader(html = tagList(
#   spin_loaders(6), br(), br(),
#   HTML("<em>Welcome to PI Charter! Please wait while we chart your course...</em>"), br(), br(),
#   img(src = "preload.png")),
#   color = "#7a0019",
#   fadeout = 500,
# ), 

#use waiter call
#using a full page waiter that pops up while page is loading and disappearing
#  waiterPreloader(html = tagList(
#    spin_loaders(6),
#    br(), #line break
#    br(),
#    HTML("I'm thinking"),
#    br(),
#    br(),
#    color = "#51C0B6",
#    fadeout = 500
#  )),

  
#DIVIDE THIS PAGE LEVEL DIV INTO 2 ROWS

  
    div(id = "toprow",
        
        div(id = "topleftbuffer",
            
            imageOutput("milfoilimg1")
            
            ),
        div(id = "titleandlogos",
            
            div(id="title",
                
              span(HTML("<h1 id ='apptitle'>MilfoilMapper</h1>"))
                
             ),
            div(id="logos",
                
                imageOutput("logos")
                
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
                            #making our little info button next to the filter
                            choices = state_codes,
                            selectize = TRUE,
                            multiple = TRUE,
                            selected = c("All" = "All")), 
                
                selectInput("Filter_Counties", #inputID argument
                            div("Pick A County"),
                            c("All" = "All", sort(unique(MSU_db_markers$County))), #choices argument
                            multiple = TRUE,
                            selected = c("All" = "All")),
                
                hidden(selectInput("Filter_LakeS",
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
                
                #CLEAR ALL FILTER BUTTONS     
                div(id="floatbutton", 
                    
                    actionButton("reset_button",
                             "Clear Filters")
                  )
                ),
            
            div(id = "info",
                
                htmlOutput("general_info"),
            
            )
            ),
        
        div(id = "map",
            
            leafletOutput("milfoil_map", height = "96%")
            
            )
        
        ), #End middle row
    
    div(id= "bottomrow",
        
        div(id = "bottomleftbuffer",
            
            imageOutput("milfoilimg3")
            
            ),
        
        div(id = "footer",
            
            HTML("<p>Questions, suggestions or bugs? Please email them to Ashley at <a href = 'mailto:ashley.wolfe3@montana.edu'>ashley.wolfe3@montana.edu</a>.<br>The data on this website was last updated 7/1/2023.</p>")
            
            ),
        
        div(id = "bottomrightbuffer",
            
            imageOutput("milfoilimg4")
            
            )
        
        )
    
) #END OF PAGE

