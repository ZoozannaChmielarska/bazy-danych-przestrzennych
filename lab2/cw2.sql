--3
CREATE EXTENSION postgis;

--4
CREATE TABLE buildings(
	id INT PRIMARY KEY,
	geometry GEOMETRY,
	name VARCHAR(50)
);

CREATE TABLE roads(
	id INT PRIMARY KEY,
	geometry GEOMETRY,
	name VARCHAR(50)
);

CREATE TABLE poi(
	id INT PRIMARY KEY,
	geometry GEOMETRY,
	name VARCHAR(50)
);


--5
INSERT INTO buildings(id, geometry, name)
VALUES 
(1, 'POLYGON((8 1.5, 10.5 1.5, 10.5 4, 8 4, 8 1.5))', 'BuildingA'),
(2, 'POLYGON((4 5, 6 5, 6 7, 4 7, 4 5))', 'BuildingB'),
(3, 'POLYGON((3 6, 5 6, 5 8, 3 8, 3 6))', 'BuildingC'),
(4, 'POLYGON((9 8, 10 8, 10 9, 9 9, 9 8))', 'BuildingD'),
(5, 'POLYGON((1 1, 2 1, 2 2, 1 2, 1 1))', 'BuildingF');

INSERT INTO roads(id, geometry, name)
VALUES
(1,'LINESTRING(0 4.5, 12 4.5)','RoadX'),
(2,'LINESTRING(7.5 10.5, 7.5 0)','RoadY');

INSERT INTO poi(id, geometry, name)
VALUES
(1,'POINT(1 3.5)','G'),
(2,'POINT(5.5 1.5)','H'),
(3,'POINT(9.5 6)','I'),
(4,'POINT(6.5 6)','J'),
(5,'POINT(6 9.5)','K');

--6
--a
SELECT SUM(ST_Length(geometry))
FROM roads
--b
SELECT ST_AsText(geometry) AS wtk, ST_Area(geometry) AS area, ST_Perimeter(geometry) AS perimeter
FROM buildings
WHERE name='BuildingA'
--c
SELECT name, ST_Area(geometry) AS area
FROM buildings
ORDER BY name ASC
--d
WITH ranked AS (
	SELECT name, geometry,
	DENSE_RANK() OVER(ORDER BY ST_Area(geometry) DESC) AS rank
	FROM buildings
)
SELECT name, ST_Perimeter(geometry) AS perimeter
FROM ranked
WHERE rank<3
--e
SELECT ST_Distance(P.geometry, B.geometry) AS min_dist
FROM poi AS P, buildings AS B
WHERE P.name='K' AND B.Name='BuildingC'
--f
WITH B_buffer AS(
	SELECT ST_AsText(ST_Buffer(geometry, 0.5)) AS b_coords
	FROM buildings
	WHERE name='BuildingB'
), C_building AS(
	SELECT geometry
	FROM buildings
	WHERE name='BuildingC'
)
SELECT ST_Area(ST_Difference(C.geometry, B.b_coords)) AS area
FROM B_buffer AS B
CROSS JOIN C_building AS C
--g
WITH r_val AS (
	SELECT ST_Y(ST_Centroid(geometry)) AS r_y_val
	FROM roads
	WHERE name='RoadX'
), b_val AS (
	SELECT ST_Y(ST_Centroid(geometry)) AS b_y_val, name
	FROM buildings
)
SELECT B.name
FROM r_val AS R
CROSS JOIN b_val AS B
WHERE b_y_val>r_y_val
--h
SELECT ST_Area(ST_SymDifference(geometry,'POLYGON((4 7, 6 7, 6 8, 4 8, 4 7))'))
FROM buildings
WHERE name='BuildingC'

