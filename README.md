### Demos by QGIS found on report: https://github.com/ndycuong/GIS-spatialData/blob/main/report.pdf  

### GIS-postgreSQL
Spatial data Query from .osm data(Open Street Map) stored on postgreSQL  

  
Description: This is a course project in order to store, organize spatial data and query them by finding point and road  
- Here I used SQL and Python for support, also with **pgrouting** vs **dijkstra** 

  
-data taken from Open Street Map, .osm , .shp.  
-using postgreSQL for storing data, additionally with postGIS and QGis for visualizing geospatial information.  
-goal: querying and generating function to finding one/many points or road(multiline) with given cases.  

** Some issues and their solutions are presented in the REPORT , as well as a section comparing different methods

   Additionally, database used index gist for geometry field. In my database, this is on WAY.  
   
   Some useful link  
   1. For seting up postgresSQL, postGis and install, import osm data from Open Street Map: https://youtu.be/ydEnrqZBj48
   2. For using Pgrouting: https://mapscaping.com/getting-started-with-pgrouting/
   3. For further understand about NN-IER: https://www.vldb.org/conf/2003/papers/S24P02.pdf

  * We display the results on QGIS. To learn more about QGIS, follow by: https://www.youtube.com/@GISITTools.
  
   
   
   
   

