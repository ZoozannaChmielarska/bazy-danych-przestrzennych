--CREATE EXTENSION postgis;
--ex1 
CREATE TABLE obiekty(
	id SERIAL PRIMARY KEY,
	name VARCHAR(10),
	geometry geometry
);


INSERT INTO obiekty(id, name, geometry)
VALUES
(1, 'obiekt1', 
        ST_Collect(
            ARRAY[
                ST_SetSRID(ST_GeomFromText('LINESTRING(0 1, 1 1)'), 0),
                ST_SetSRID(ST_GeomFromText('CIRCULARSTRING(1 1, 2 0, 3 1)'), 0),
                ST_SetSRID(ST_GeomFromText('CIRCULARSTRING(3 1, 4 2, 5 1)'), 0),
                ST_SetSRID(ST_GeomFromText('LINESTRING(5 1, 6 1)'), 0)])
);

INSERT INTO obiekty(id, name, geometry)
VALUES
(2, 'obiekt2', 
    ST_BuildArea(
        ST_Collect(
            ARRAY[ST_SetSRID(ST_GeomFromText('LINESTRING(10 6, 14 6)'), 0),
                ST_SetSRID(ST_GeomFromText('CIRCULARSTRING(14 6, 16 4, 14 2)'), 0),
                ST_SetSRID(ST_GeomFromText('CIRCULARSTRING(14 2, 12 0, 10 2)'), 0),
                ST_SetSRID(ST_GeomFromText('LINESTRING(10 2, 10 6)'), 0),
                ST_Buffer(ST_SetSRID(ST_MakePoint(12, 2), 0), 1, 6000)]))
);

INSERT INTO obiekty(id, name, geometry)
VALUES
(3, 'obiekt3', 
    ST_SetSRID(ST_GeomFromText('POLYGON((12 13, 7 15, 10 17, 12 13))'), 0)
);

INSERT INTO obiekty(id, name, geometry)
VALUES
(4, 'obiekt4', 
    ST_SetSRID(ST_GeomFromText('LINESTRING(20 20, 25 25, 27 24, 25 22, 26 21, 22 19, 20.5 19.5)'), 0)
);

INSERT INTO obiekty(id, name, geometry)
VALUES
(5, 'obiekt5', 
    ST_SetSRID(ST_GeomFromText('MULTIPOINT((30 50 59), (38 32 234))'), 0)
);

INSERT INTO obiekty(id, name, geometry)
VALUES
(6, 'obiekt6', 
    ST_Collect(
        ST_SetSRID(ST_GeomFromText('LINESTRING(1 1, 3 2)'), 0),
        ST_SetSRID(ST_GeomFromText('POINT(4 2)'), 0)
    )
);

--export svg, w celu porównania wizualizacji
SELECT ST_AsSVG(geometry) AS svg
FROM obiekty
WHERE id = 1;


--ex2
SELECT ST_Area(ST_Buffer(ST_ShortestLine(O1.geometry, O2.geometry),5))
FROM obiekty AS O1, obiekty AS O2
WHERE O1.id=3 AND O2.id=4


--ex3
--Obiekt POLYGON musi być mieć identyczny pierwszy i ostatni punkt 
--w celu zamknięcia obwodu, a więc stworzenia ograniczonej powierzchni

--ST_AddPoint->dodajemy na końcu geometry pierwszy punkt, aby zamknąć poligon 

UPDATE obiekty
SET geometry = ST_MakePolygon(ST_AddPoint(geometry, ST_StartPoint(geometry)))
WHERE id=4;

--sprawdzenie
SELECT id, name, ST_AsText(geometry) AS geometry_text
FROM obiekty
WHERE id = 4;


--ex4
INSERT INTO obiekty
SELECT 7,'obiekt7',ST_Union(O3.geometry, O4.geometry)
FROM obiekty AS O3, obiekty AS O4
WHERE O3.id=3 AND O4.id=4;

SELECT id, name, ST_AsText(geometry) AS geometry_text
FROM obiekty
WHERE id=7;


--ex5
--suma pól poszczególnych buforów
SELECT ST_Area(ST_Buffer(geometry,5)) AS buffer_area
FROM obiekty
WHERE ST_HasArc(geometry)=FALSE

--suma pól wszystkich buforów
SELECT SUM(ST_Area(ST_Buffer(geometry,5))) AS total_buffer_area
FROM obiekty
WHERE ST_HasArc(geometry)=FALSE
