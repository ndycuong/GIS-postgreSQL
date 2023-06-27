### GIS-postgreSQL
Spatial data Query from .osm data(Open Street Map) stored on postgreSQL  

  
Description: This is a course project in order to store, organize spatial data and query them by finding point and road  

  
-data taken from Open Street Map, .osm , .shp.  
-using postgreSQL for storing data, additionally with postGIS and QGis for visualizing geospatial information.  
-Goal: querying and generating function to finding one/many points or road(multiline) with given cases.  

(1,2,3) in knn.sql  

  1. Find KNN restaurant point that is nearest to the given point with long lat or geometry 
  2. Find density of restaurants in an area
  3. Find road/path using djisktra - pgrouting for finding the shortest path to KNN restaurants from the given point
  4. ... doing

