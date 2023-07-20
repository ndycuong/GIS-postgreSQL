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


Updating:
1. Using NN IER for finding NN point that has the shortest real network routing by pgrouting-dijkstra from given point
   
2. Finding NN to 2 given point
   2.1. Finding NN of 2 given point, then calculating the max euclid distance of these 2 NN. Finding candidate that is within in this max distance by 2 given point. After that, taking intersection or union of 2 set of candidates. Finally, calculating network routing to all new candidate and pick the shorest => best result in set of candidate.
   2.2. Finding NN by IER above, then calculating the min network routing distance of these 2 NN to 2 given point. Finding candidate that is within in this max distance by any given point. Finally, calculating network routing to all candidate and pick the shorest => the best real result, because the max network routing is the distance to limit the candidate set, so if in this distance that can't find a point with a shorter network routing, then the point is NN which I mentioned at the beginning with min network routing distance must be the result.
  => in 2.1 may not find the best candidate but it costs less than 2.2 whose result is the best result.

3. Finding Hospital and ATM that has shortest network routing to Restaurant (limitation in specific region)
   Starting with Hospital because its density is small, finding the nearest euclide distance point of Restaurant. From this Restaurant, continue to find nearest euclide distance point of ATM. Then comparison to 2 distance and pick longer one. After that, finding all Hospital and ATM that is within this longer distance. With each set of (Hosptal and ATM), calculating network routing to Restaurant and pick the shortest. Finally, proceeding in this manner, iterating through all the hospitals located within the specified region.
   => This approach allows for achieving favorable result from the candidate set at a small cost, but it does not ensure that the results obtained are actually the best possible.

1. Function IED()
2. 2.1. Function intersection(),
   2.2. Function path2point()
3. Function bePoint()

   Additionally, database used index gist for geometry field. In my database, this is on WAY.
   
   Some useful link
   1. For seting up postgresSQL, postGis and install, import osm data from Open Street Map: https://youtu.be/ydEnrqZBj48
   2. For using Pgrouting: https://mapscaping.com/getting-started-with-pgrouting/
   
   
   

