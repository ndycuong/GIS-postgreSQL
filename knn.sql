drop table geometries
CREATE INDEX idx_vn_label ON geometries_vn USING gist (way);


--determining longtitude and latitude of point's geometry 
SELECT planet_osm_point.*,
ST_X(planet_osm_point.way) AS X1, --point x
ST_Y(planet_osm_point.way) AS Y1, --point y
ST_X(ST_TRANSFORM(planet_osm_point.way,4756)) AS LONG, -- longitude point x VN-2000
ST_Y(ST_TRANSFORM(planet_osm_point.way,4756)) AS LAT, --latitude point y VN-2000
ST_ASTEXT(planet_osm_point.way) AS XY, --wkt point xy
ST_ASTEXT(ST_TRANSFORM(planet_osm_point.way,4756)) AS LongLat 
--using st_transform to get wkt with longitude and latitude (4674 is the VN-2000 by vietnam)
INTO geometries_vn
FROM
planet_osm_point


select * from geometries
limit 10

--determining longtitude and latitude of point's geometry 
SELECT planet_osm_point.*,
ST_X(planet_osm_point.way) AS X1, --point x
ST_Y(planet_osm_point.way) AS Y1, --point y
ST_X(ST_TRANSFORM(planet_osm_point.way,4674)) AS LONG, -- longitude point x SIRGAS 2000
ST_Y(ST_TRANSFORM(planet_osm_point.way,4674)) AS LAT, --latitude point y SIRGAS 2000
ST_ASTEXT(planet_osm_point.way) AS XY, --wkt point xy
ST_ASTEXT(ST_TRANSFORM(planet_osm_point.way,4674)) AS LongLat 
--using st_transform to get wkt with longitude and latitude (4674 is the SIRGAS 2000 SRC by south america)
INTO geometries
FROM
planet_osm_point

--find 5 restaurants that is nearest to given query point using Euclide distance
SELECT * 
FROM geometries 
WHERE amenity = 'restaurant' 
ORDER BY ST_Distance( 
  ST_Transform(ST_SetSRID(ST_MakePoint(long, lat), 4326), 3857),    -- transform is  like convert 4326: hệ tọa độ kinh vĩ to 3857: thể hiện trái đát trên khongo gian 2 chiều để có thể tính đc k/c
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




----find average distance between 2 diffirent restaurants in area Using Euclide
select avg(distance) 
from (SELECT 
    h.osm_id, a.osm_id, 
    ST_Distance(h.way, a.way) AS distance 
FROM 
    geometries_vn h 
    CROSS JOIN geometries_vn a 
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


	
---- find path&cost between 2 given point to 1 point Using pgRouting, route distance
WITH start1 AS (
  SELECT topo.source
  FROM osm_2po_4pgr as topo
  ORDER BY topo.geom_way <-> ST_SetSRID(
    ST_GeomFromText('POINT(105.795665 21.00939500040452)'),4326) --point(long lat)	
  LIMIT 1)

,start2 as (
	SELECT topo.source
  FROM osm_2po_4pgr as topo
  ORDER BY topo.geom_way <-> ST_SetSRID(
    ST_GeomFromText('POINT(105.8452161 21.00105440040437)'),4326) --point(long lat)	
  LIMIT 1	
 )
,destination AS (
  SELECT topo.source 
  FROM osm_2po_4pgr as topo
  ORDER BY topo.geom_way <-> ST_SetSRID(
    ST_GeomFromText('POINT(105.810844 20.99971330040434)'),4326) --point(long lat)	
  LIMIT 1
)

select sum(fi.route_cost) , ST_Union(fi.route_geometry)
from
(
	SELECT (di.cost) AS route_cost, ST_Union(pt.geom_way) AS route_geometry
FROM pgr_dijkstra(
  'SELECT id, source, target, ST_Length(ST_Transform(geom_way, 3857)) AS cost FROM osm_2po_4pgr',
  ARRAY(select source FROM destination),-- union select source from start2),
  ARRAY(SELECT source FROM start1 union select source from start2)
,  directed := false
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
  LIMIT 5
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


CREATE INDEX idx_vn_label ON geometries_vn USING gist (way);


--FILTER 10NN to 1NN having shorest lost by dijkstra
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
limit 1)
;


--ST_Union(pt.geom_way) return binary form
--ST_AsText(ST_Union(geom_way)) return multiline-string
-- display network routing path from multilinestring
select ST_GeomFromText(
'MULTILINESTRING((105.8938123 21.0394444,105.8938681 21.0394183,105.8939826 21.0393647),(105.8939826 21.0393647,105.8940112 21.0393514,105.8942581 21.0392359,105.8948021 21.0389814),(105.8948021 21.0389814,105.8948861 21.0389422,105.8950552 21.038863,105.8951641 21.0388121,105.8955774 21.0386188,105.8956393 21.0385899,105.8969721 21.0379665,105.8970381 21.0379356),(105.8971672 21.0379092,105.8970381 21.0379356),(105.8972835 21.0378535,105.8971672 21.0379092),(105.8981092 21.0374512,105.8973924 21.0378014,105.8972835 21.0378535),(105.8981163 21.0374473,105.8981092 21.0374512),(105.898358 21.0373148,105.8981163 21.0374473),(105.898493 21.0372407,105.898358 21.0373148),(105.8991353 21.0368849,105.8988865 21.037025,105.898493 21.0372407),(105.8996635 21.036587,105.8991353 21.0368849),(105.8997106 21.0366409,105.8996857 21.0366129,105.8996635 21.036587),(105.8998158 21.0367523,105.899742 21.0366798,105.8997106 21.0366409),(105.8999232 21.0369015,105.8998158 21.0367523),(105.8999232 21.0369015,105.8998089 21.0369512,105.8995975 21.0370726,105.8994383 21.0371892,105.8992986 21.0373148,105.8991577 21.0374644,105.8990429 21.037601,105.8988984 21.0377877,105.8987631 21.0379713,105.8986521 21.0381531,105.8985233 21.0383983),(105.8985233 21.0383983,105.8984238 21.0386046,105.8983427 21.0388115),(105.8983427 21.0388115,105.8983204 21.0388651),(105.8983204 21.0388651,105.8981579 21.039313),(105.8981579 21.039313,105.8981056 21.0394564),(105.8981056 21.0394564,105.898064 21.0395734,105.8978025 21.0403092),(105.8978025 21.0403092,105.8976708 21.0406467),(105.8976708 21.0406467,105.8972767 21.0416797,105.8971641 21.0419227),(105.8971641 21.0419227,105.8970951 21.0420868,105.8968964 21.0424793),(105.8968964 21.0424793,105.8971344 21.0426425),(105.8971344 21.0426425,105.8974777 21.0428859),(105.8974777 21.0428859,105.8975877 21.0429659),(105.8975877 21.0429659,105.8976877 21.0430559),(105.8976877 21.0430559,105.8979977 21.0433059),(105.8979977 21.0433059,105.8982208 21.0435281),(105.8982208 21.0435281,105.8985639 21.0438697))',
    4326
  )--1794.700129499897
  from geometries


