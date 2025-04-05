#
# NYC Taxi Zone Selection Application
# This Shiny app allows users to select start and end points in NYC taxi zones
# across Manhattan, Queens, and Brooklyn boroughs.
#

# Load required libraries
library(shiny)
library(bslib)
library(sf)
library(leaflet)

# Define valid boroughs for this application
UniqueBorough <- c("Manhattan", "Queens", "Brooklyn")

NycTaxiZone <- read_sf("taxi_zones/taxi_zones.shp") |>
  subset(borough %in% UniqueBorough) |>
  st_transform(4326)

# Solving duplicated ID problem
RowsToCombine <- NycTaxiZone[NycTaxiZone$zone == "Corona", ]
RowsToCombine$geometry[1] <- st_union(RowsToCombine)

NycTaxiZone <- rbind(
  NycTaxiZone[NycTaxiZone$zone != "Corona", ],
  RowsToCombine[1L,]
)


# Create user-friendly zone identifiers
NycTaxiZone$new_id <- paste0(NycTaxiZone$borough, " | ", NycTaxiZone$zone)

# Create valid zone selection options, including blank for no selection
ValidZones <- c('Select a Zone' = "", NycTaxiZone$new_id)

# UI definition with enhanced layout and information - using page_fillable for full width
ui <- page_sidebar(
  title = "NYC Taxi Zone Selection Dashboard",
  theme = bs_theme(version = 5 ,bootswatch = "lux"),
  fillable = TRUE, # Make page use full width
  
  sidebar = sidebar(
    title = "Select Locations",
    width = 400, # Fixed width for sidebar
    
    # App description for users
    p("Select start and end points by using the dropdowns or clicking directly on the map."),
    
    # Input controls
    selectInput("StartPoint",
                "Start Zone", 
                choices = ValidZones),
    
    selectInput("EndPoint", 
                "End Zone", 
                choices = ValidZones),
    
    # Reset button
    actionButton("resetSelections", "Reset Selections", 
                 class = "btn-secondary btn-sm w-100 mt-3")
  ),
  
  # Main content
  leafletOutput("mymap", height = "calc(100vh - 80px)")
)

# Server logic
server <- function(input, output, session) {
  
  # Initialize reactive values to store state
  rv <- reactiveValues(
    prior_start_id = NULL,
    prior_end_id = NULL
  )
  
  # Function to render the initial map
  output$mymap <- renderLeaflet({
    
    leaflet(NycTaxiZone) |>
      addProviderTiles(providers$CartoDB.Positron) |>  # Better basemap
      setView(-73.90675, 40.7180, zoom = 11) |>
      addPolygons(layerId = ~new_id,
                  stroke = TRUE,
                  color = "black",
                  weight = 0.8,
                  fillColor = "grey",
                  fillOpacity = 0.4,
                  popup = ~new_id,
                  highlightOptions = highlightOptions(
                    weight = 2,
                    color = "#666",
                    fillOpacity = 0.7,
                    bringToFront = TRUE
                  ))
  })
  
  # Handle map click events
  observeEvent(input$mymap_shape_click, {
    clicked_id <- input$mymap_shape_click$id
    
    # Logic for handling Start Point selection
    if (paste0(input$StartPoint, "2") == clicked_id) {
      # Clicking on already selected start point deselects it
      rv$prior_start_id <- input$StartPoint
      updateSelectInput(session, inputId = "StartPoint", selected = "")
    } else if (input$StartPoint == "") {
      # If no start point is selected, set the clicked zone as start
      updateSelectInput(session, inputId = "StartPoint", selected = clicked_id)
    } else if (!input$StartPoint %in% c("", substr(clicked_id, 1, nchar(clicked_id) - 1))) {
      # Logic for handling End Point selection when Start is already set
      if (paste0(input$EndPoint, "2") == clicked_id) {
        # Clicking on already selected end point deselects it
        rv$prior_end_id <- input$EndPoint
        updateSelectInput(session, inputId = "EndPoint", selected = "")
      } else if (input$EndPoint == "") {
        # If no end point is selected, set the clicked zone as end
        updateSelectInput(session, inputId = "EndPoint", selected = clicked_id)
      }
    }
  })
  
  # Module for handling zone highlighting
  highlightZone <- function(zoneId, color, proxy, previous_id, layerId_suffix) {
    # Remove previous highlight if exists
    if (!is.null(previous_id)) {
      proxy |> removeShape(layerId = paste0(previous_id, layerId_suffix))
    }
    
    # Only highlight if valid zone is selected
    if (zoneId != "") {
      # Filter data for the selected zone
      filtered_data <- NycTaxiZone[NycTaxiZone$new_id == zoneId, ]
      
      if (nrow(filtered_data) > 0) {
        # Add polygon with highlight color
        proxy |>
          addPolygons(
            data = filtered_data,
            layerId = paste0(zoneId, layerId_suffix),
            stroke = TRUE,
            color = "black",
            weight = 1.2,
            fillColor = color,
            fillOpacity = 0.85,
            popup = zoneId
          )
        
        return(zoneId)
      }
    }
    return(NULL)
  }
  
  # Observer for Start Point changes
  observeEvent(input$StartPoint, {
    rv$prior_start_id <- highlightZone(
      input$StartPoint, 
      "yellow", 
      leafletProxy("mymap"), 
      rv$prior_start_id, 
      "2"
    )
  })
  
  # Observer for End Point changes
  observeEvent(input$EndPoint, {
    rv$prior_end_id <- highlightZone(
      input$EndPoint, 
      "orange",  # Different color for end point
      leafletProxy("mymap"), 
      rv$prior_end_id, 
      "2"
    )
  })
  
  # Reset button handler
  observeEvent(input$resetSelections, {
    # Clear selections
    updateSelectInput(session, "StartPoint", selected = "")
    updateSelectInput(session, "EndPoint", selected = "")
    
    # Remove highlights from map
    proxy <- leafletProxy("mymap")
    if (!is.null(rv$prior_start_id)) {
      proxy |> removeShape(layerId = paste0(rv$prior_start_id, "2"))
      rv$prior_start_id <- NULL
    }
    if (!is.null(rv$prior_end_id)) {
      proxy |> removeShape(layerId = paste0(rv$prior_end_id, "2"))
      rv$prior_end_id <- NULL
    }
  })
  
  # Observe window resize and adjust map size
  observe({
    session$onFlushed(function() {
      session$sendCustomMessage(type = "leaflet-resize", message = "mymap")
    })
  })
}

# Run the application 
shinyApp(ui = ui, server = server)