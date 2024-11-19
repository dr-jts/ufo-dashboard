#  UFO Risk Dashboard
Code for a UFO Risk Dashboard with [PostGIS](https://postgis.net/), [H3-pg](https://github.com/zachasme/h3-pg), [pg_tileserv](https://github.com/CrunchyData/pg_tileserv), [pg_featureserv](https://github.com/CrunchyData/pg_featureserv), [MapLibre](https://maplibre.org/).

![](ufo_risk_dashboard.png)

## Datasets

### US UFO Sightings

* Format: CSV
* Link: [Ufo Sightings CSV File](https://corgis-edu.github.io/corgis/csv/ufo_sightings/)

### US Wind Turbine locations

* Format: CSV
* Link: [Wind Turbines CSV File](https://corgis-edu.github.io/corgis/csv/wind_turbines/)

### Kontur population data in H3

* Format: Geopackage
* Link: [Global Population Density for 22km (Res 4) H3 Hexagons](https://data.humdata.org/dataset/kontur-population-dataset-22km)

## Code Guide
### pg_tileserv Functions
* https://github.com/dr-jts/ufo-dashboard/blob/main/ufo_h3.sql
* https://github.com/dr-jts/ufo-dashboard/blob/main/ufo_h3_cluster.sql
* https://github.com/dr-jts/ufo-dashboard/blob/main/ufo_turbine_risk.sql

## Views for pg_featureserv
* https://github.com/dr-jts/ufo-dashboard/blob/main/ufo_turbine_risk_h3_r6.sql

