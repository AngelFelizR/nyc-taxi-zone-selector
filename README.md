# NYC Taxi Zone Selection Dashboard

This Shiny application provides an interactive map-based tool for selecting start and end points across NYC taxi zones, limited to the boroughs of **Manhattan**, **Queens**, and **Brooklyn**.

## Features

- Interactive selection of start and end taxi zones
- Dropdown menus or direct map clicking for user-friendly interaction
- Dynamic zone highlighting
- Reset button for clearing selections
- Responsive UI using Bootstrap 5 and Leaflet integration

## Technologies Used

- **R** with the following packages:
  - `shiny`
  - `bslib`
  - `sf`
  - `leaflet`

## Data

The application uses the official NYC Taxi Zones shapefile:
```
taxi_zones/taxi_zones.shp
```
Only zones within Manhattan, Queens, and Brooklyn are used.

Special handling is applied to resolve a duplication issue in the "Corona" zone.

## Running the App

Ensure you have the required libraries installed. Then run:

```r
shiny::runApp()
```

## Project Structure

- `server`: Logic for zone highlighting and event handling
- `ui`: Responsive layout with map and control panel
- `taxi_zones/`: Folder containing the shapefile data

## License

This project is provided for educational and demonstrative purposes.