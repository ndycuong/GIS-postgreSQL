--determining longtitude and latitude of point's geometry 
SELECT planet_osm_point.*,
ST_X(planet_osm_point.way) AS X1, --point x
ST_Y(planet_osm_point.way) AS Y1, --point y
ST_X(ST_TRANSFORM(planet_osm_point.way,4674)) AS LONG, -- longitude point x SIRGAS 2000
ST_Y(ST_TRANSFORM(planet_osm_point.way,4674)) AS LAT, --latitude point y SIRGAS 2000
ST_ASTEXT(planet_osm_point.way) AS XY, --wkt point xy
ST_ASTEXT(ST_TRANSFORM(planet_osm_point.way,4674)) AS LongLat --using st_transform to get wkt with longitude and latitude (4674 is the SIRGAS 2000 SRC by south america)
INTO geometries
FROM
planet_osm_point

--find 5 restaurants that is nearest to given query point using Euclide distance
SELECT * 
FROM geometries 
WHERE amenity = 'restaurant' 
ORDER BY ST_Distance( 
  ST_Transform(ST_SetSRID(ST_MakePoint(long, lat), 4326), 3857), 
  ST_Transform(ST_SetSRID(ST_MakePoint(105.8452161, 21.00105440040437), 4326), 3857)  --query point
)  
LIMIT 5; 


--find 1 restaurant that is nearest to given 2 query points Using Euclide distance
SELECT * 
FROM geometries 
WHERE amenity = 'restaurant' 
ORDER BY 
  ST_Distance(geometries.longlat::geography, ST_SetSRID(ST_MakePoint(105.83967809999999, 21.000431500404364), 4326)::geography) + 
  ST_Distance(geometries.longlat::geography, ST_SetSRID(ST_MakePoint(105.84166189999999, 21.00160820040438), 4326)::geography) 
LIMIT 1; 

----find 1 restaurant that is nearest to given 2 query points Using pgRouting
--?

--find all restaurant in an area
--find S of polygon
--Mật độ quán ăn trong khu vực hai bà trưng
with num as(SELECT count(*) as numOf
FROM geometries
WHERE ST_Within(
  ST_SetSRID(ST_MakePoint(long, lat), 4326),
  ST_Transform(
    (
      SELECT way
      FROM planet_osm_polygon
      WHERE name LIKE '%Quận Hai Bà Trưng'
        AND boundary = 'administrative'
    ),
    4326
  )
)
AND amenity = 'restaurant') ,
S as(
--find Square
SELECT ST_Area(way) /1000000 as square--km2   --/ (1609.34 * 1609.34) miles
FROM planet_osm_polygon
WHERE name LIKE '%Quận Hai Bà Trưng'
    AND boundary = 'administrative') 
select numOf/square as soNhtrenkm2 from num,S



-- Find 5 Restaurants closest to both ATMs and Hospitals (undefined) in an area
--???????


----find average distance between 2 diffirent restaurants in area Using Euclide
select avg(distance) 
from (SELECT 
    h.osm_id, a.osm_id, 
    ST_Distance(h.way, a.way) AS distance 
FROM 
    geometries h 
    CROSS JOIN geometries a 
WHERE 
    h.amenity = 'restaurant' 
    AND a.amenity = 'restaurant' 
    AND ST_Within(
        ST_SetSRID(ST_MakePoint(a.long, a.lat), 4326),
        ST_Transform(
            (
                SELECT way
                FROM planet_osm_polygon
                WHERE name LIKE '%Quận Hai Bà Trưng'
                AND boundary = 'administrative'
            ),
            4326
        )
    ) and ST_Within(
        ST_SetSRID(ST_MakePoint(h.long, h.lat), 4326),
        ST_Transform(
            (
                SELECT way
                FROM planet_osm_polygon
                WHERE name LIKE '%Quận Hai Bà Trưng'
                AND boundary = 'administrative'
            ),
            4326
        )
    )
    AND h.osm_id < a.osm_id 
ORDER BY distance desc) as res


	
---- find path&cost between 2 given point Using pgRouting, route distance
WITH start AS (
  SELECT topo.source 
  FROM osm_2po_4pgr as topo
  ORDER BY topo.geom_way <-> ST_SetSRID(
    ST_GeomFromText('POINT(105.795665 21.00939500040452)'),4326) --point(long lat)	
  LIMIT 1
),
destination AS (
  SELECT topo.source 
  FROM osm_2po_4pgr as topo
  ORDER BY topo.geom_way <-> ST_SetSRID(
    ST_GeomFromText('POINT(105.810844 20.99971330040434)'),4326) --point(long lat)	
  LIMIT 1
)

select sum(fi.route_cost) , ST_Union(fi.route_geometry)
from
( SELECT (di.cost) AS route_cost, ST_Union(pt.geom_way) AS route_geometry
FROM pgr_dijkstra(
  'SELECT id, source, target, ST_Length(ST_Transform(geom_way, 3857)) AS cost FROM osm_2po_4pgr',
  ARRAY(SELECT source FROM start),
  ARRAY(SELECT source FROM destination),
  directed := false
) AS di
JOIN osm_2po_4pgr AS pt ON di.edge = pt.id
GROUP BY di.cost) as fi;



--find path pgRouting from a given query to KNN having shorest st_distance:
---------find point that haing the shortest Euclide distance and find road
WITH tenNN AS (
  SELECT long, lat
  FROM geometries
  WHERE amenity = 'restaurant'
  ORDER BY ST_Distance(
    ST_Transform(ST_SetSRID(ST_MakePoint(long, lat), 4326), 3857),
    ST_Transform(ST_SetSRID(ST_MakePoint(105.8452161, 21.00105440040437), 4326), 3857)
  )
  LIMIT 10
)
SELECT 
  point.long,point.lat,
  (
    SELECT ST_Union(geom_way) AS route
    FROM pgr_dijkstra(
      'SELECT id, source, target,ST_Length(ST_Transform(geom_way, 3857)) AS cost FROM osm_2po_4pgr',
      (
        SELECT source
        FROM osm_2po_4pgr
        ORDER BY geom_way <-> ST_SetSRID(ST_MakePoint(105.83589009999999, 21.016768700404654), 4326)
        LIMIT 1
      ),
      ARRAY(
        SELECT topo.source
        FROM osm_2po_4pgr AS topo
        ORDER BY topo.geom_way <-> ST_SetSRID(ST_MakePoint(point.long, point.lat), 4326)
        LIMIT 1
      ),
      directed := false
    ) AS di
    JOIN osm_2po_4pgr AS pt ON di.edge = pt.id
  ) AS route
FROM tenNN AS point
;


CREATE INDEX idx_any_label ON geometries USING gist (way);


--FILTER 10NN to 5NN having shorest lost by dijkstra
--find point, path that has the shortest route by Dijkstra from KNN nearest by Euclide
EXPLAIN(WITH tenNN AS (
  SELECT long, lat
  FROM geometries
  WHERE amenity = 'restaurant'
  ORDER BY ST_Distance(
    ST_Transform(ST_SetSRID(ST_MakePoint(long, lat), 4326), 3857),
    ST_Transform(ST_SetSRID(ST_MakePoint(105.8452161, 21.00105440040437), 4326), 3857)
  )
  LIMIT 10
)
 SELECT 
  point.long,
  point.lat,
  lost_route.lost AS lost,
  lost_route.route_geometry
FROM tenNN AS point
CROSS JOIN LATERAL (
  SELECT 
    sum(di.cost) AS lost, 
    ST_Union(pt.geom_way) AS route_geometry
  FROM pgr_dijkstra(
    'SELECT id, source, target, ST_Length(ST_Transform(geom_way, 3857)) AS cost FROM osm_2po_4pgr',
    (
      SELECT source
      FROM osm_2po_4pgr
      ORDER BY geom_way <-> ST_SetSRID(ST_MakePoint(105.83589009999999, 21.016768700404654), 4326)
      LIMIT 1
    ),
    ARRAY(
      SELECT topo.source
      FROM osm_2po_4pgr AS topo
      ORDER BY topo.geom_way <-> ST_SetSRID(ST_MakePoint(point.long, point.lat), 4326)
      LIMIT 1
    ),
    directed := false
  ) AS di
  JOIN osm_2po_4pgr AS pt ON di.edge = pt.id
) AS lost_route
order by lost
limit 5)
;


