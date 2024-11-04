/*

Wczytywanie plików według formuły:
.\shp2pgsql.exe -I -s SRID "plik.shp" public.nazwa_tabeli
| psql -h localhost -p 5432 -U postgres -d nazwa_database

Przykład:
.\shp2pgsql.exe -I -s 4326 "T2018_KAR_BUILDINGS.shp" public.buildings2018 
| psql -h localhost -p 5432 -U postgres -d cw3

*/


--ex1
SELECT *
FROM buildings2019 AS b19
LEFT JOIN buildings2018 AS b18 
ON b19.geom = b18.geom
WHERE b18.geom IS NULL;


--ex2 --------------------------
WITH new_buildings_buffer AS (
	SELECT ST_Buffer(ST_Union(b19.geom), 0.005) AS b_geom_buffer
	FROM buildings2019 AS b19
	LEFT JOIN buildings2018 AS b18 
	ON b19.geom = b18.geom
	WHERE b18.geom IS NULL
),
new_poi AS (
	SELECT p19.*
	FROM poi2019 AS p19
	LEFT JOIN poi2018 AS p18 
	ON p19.geom = p18.geom
	WHERE p18.geom IS NULL
)
SELECT P.type, COUNT(*) AS count
FROM new_poi AS P
JOIN new_buildings_buffer AS B
ON ST_Within(P.geom, B.b_geom_buffer)
GROUP BY P.type;


--ex3
ALTER TABLE street2019
ALTER COLUMN geom TYPE geometry(MultiLineString, 4326)
USING ST_SetSRID(geom, 4326);

CREATE TABLE streets_reprojected AS
SELECT gid, link_id, st_name, ref_in_id, func_class, speed_cat, fr_speed_l, to_speed_l, dir_travel,
ST_Transform(geom, 3068) AS geometry
FROM street2019;

SELECT * FROM streets_reprojected


--ex4 
CREATE TABLE input_points (
	id INT PRIMARY KEY,
	name VARCHAR(2),
	geom geometry
);

INSERT INTO input_points(id, name, geom)
VALUES
(1,'P1','POINT(8.36093 49.03174)'),
(2,'P2','POINT(8.39876 49.00644)');

SELECT * FROM input_points


--ex5
UPDATE input_points
SET geom = ST_Transform(ST_SetSRID(geom, 4326), 3068);


--ex6
SELECT * FROM street_node;
UPDATE street_node
SET geom = ST_Transform(geom, 3068);

WITH intersections AS (
    SELECT gid, geom 
    FROM street_node
    WHERE "intersect" = 'Y'
),
line_buffer AS (
    SELECT ST_Buffer(ST_MakeLine(geom), 0.002) AS line
    FROM input_points
    WHERE "name" IN ('P1', 'P2')
)
SELECT I.gid, I.geom
FROM intersections AS I
JOIN line_buffer AS L
ON ST_Within(I.geom, L.line);


--ex7
SELECT * FROM land2019
UPDATE land2019
SET geom = ST_Transform(geom, 3068);
UPDATE poi2018
SET geom = ST_Transform(geom, 3068);

WITH shops AS (
    SELECT gid, geom
    FROM poi2019
    WHERE "type" ILIKE '%Sporting Goods Store%'
),
parks_buffer AS (
    SELECT ST_Buffer(geom, 0.003) AS p_buffer
    FROM land2019
    WHERE "type" ILIKE '%park%'
)
SELECT COUNT(S.gid)
FROM shops AS S
JOIN parks_buffer AS P
ON ST_Within(S.geom, P.p_buffer);


--ex8
UPDATE railways2019
SET geom = ST_Transform(geom, 3068);
UPDATE water2019
SET geom = ST_Transform(geom, 3068);

CREATE TABLE T2019_KAR_BRIDGES AS
SELECT ST_Intersection(R.geom, W.geom) AS geom
FROM railways2019 AS R
JOIN water2019 AS W
ON ST_Intersects(R.geom, W.geom)

SELECT * FROM T2019_KAR_BRIDGES


