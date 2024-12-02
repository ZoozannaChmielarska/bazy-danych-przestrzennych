CREATE EXTENSION postgis;
CREATE EXTENSION postgis_raster;
----
SELECT * FROM rasters.dem;
SELECT * FROM rasters.landsat8;
----
SELECT * FROM public.raster_columns;

----
--ST_Intersects-przecięcie rastra z wektorem
CREATE TABLE schema_chmielarska.intersects AS
SELECT a.rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality ILIKE 'porto';

--klucz głowny
ALTER TABLE schema_chmielarska.intersects
ADD COLUMN rid SERIAL PRIMARY KEY;

--index przestrzenny GiST
CREATE INDEX idx_intersects_rast_gist ON schema_chmielarska.intersects
USING gist (ST_ConvexHull(rast));
--T_ConvexHull: przekształca raster na geometrię (otoczke wypukłą), bo gist działa na geometrii

-- schema::name table_name::name raster_column::name --true/false
--Constraint (ograniczenie) dla typu danych: Sprawdza, czy kolumna zawiera poprawne dane rastrowe, a 
--także czy wartości w tej kolumnie są poprawnie zdefiniowane
SELECT AddRasterConstraints('schema_chmielarska'::name,
'intersects'::name,'rast'::name);

SELECT * FROM schema_chmielarska.intersects;

----
--ST_Clip-przycina raster, zostawiając tylko te jego części, które pokrywają się z obszarem geometrii
CREATE TABLE schema_chmielarska.clip AS
SELECT ST_Clip(a.rast, b.geom, true) AS rast, b.municipality
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast, b.geom) AND b.municipality like 'PORTO';

ALTER TABLE schema_chmielarska.clip
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_clip_rast_gist ON schema_chmielarska.clip
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'clip'::name,'rast'::name);

SELECT * FROM schema_chmielarska.clip;

----
--ST_Union
CREATE TABLE schema_chmielarska.union AS
SELECT ST_Union(ST_Clip(a.rast, b.geom, true)) AS rast --true -> piksele spoza obszaru wycinka są wypełnione NULL 
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.municipality ILIKE 'porto' and ST_Intersects(b.geom,a.rast);
--połączenie wyciętych fragmentów 

ALTER TABLE schema_chmielarska.union
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_union_rast_gist ON schema_chmielarska.union
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'union'::name,'rast'::name);

SELECT * FROM schema_chmielarska.union;

--przyklad
SELECT ST_Union(rast, 'MEAN') --default: LAST
FROM schema_chmielarska.clip;

----
--ST_AsRaster
CREATE TABLE schema_chmielarska.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
) 
--pobieramy wzorcowy raster, aby powstałe rastry miały tę samą rozdzielczość i układ współrzędnych
SELECT ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ILIKE 'porto';

ALTER TABLE schema_chmielarska.porto_parishes
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_porto_parishes_rast_gist ON schema_chmielarska.porto_parishes
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'porto_parishes'::name,'rast'::name);

SELECT * FROM schema_chmielarska.porto_parishes;

----
--ST_Union
--łączymu rekordy z poprzedniego przykładu w pojedynczy raster
DROP TABLE schema_chmielarska.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_chmielarska.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1
)
SELECT ST_Union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ILIKE 'porto';

ALTER TABLE schema_chmielarska.porto_parishes
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_porto_parishes_rast_gist ON schema_chmielarska.porto_parishes
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'porto_parishes'::name,'rast'::name);

SELECT * FROM schema_chmielarska.porto_parishes;

----
--ST_Tile--podział rastra na kafelki 
DROP TABLE schema_chmielarska.porto_parishes; --> drop table porto_parishes first
CREATE TABLE schema_chmielarska.porto_parishes AS
WITH r AS (
	SELECT rast FROM rasters.dem
	LIMIT 1 
)--łączymy w jeden raster i dzielimy na kafelki 128x128
SELECT ST_Tile(ST_Union(ST_AsRaster(a.geom,r.rast,'8BUI',a.id,-32767)),128,128,true,-32767) AS rast
FROM vectors.porto_parishes AS a, r
WHERE a.municipality ILIKE 'porto';

ALTER TABLE schema_chmielarska.porto_parishes
ADD COLUMN rid SERIAL PRIMARY KEY;

CREATE INDEX idx_porto_parishes_rast_gist ON schema_chmielarska.porto_parishes
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'porto_parishes'::name,'rast'::name);

SELECT * FROM schema_chmielarska.porto_parishes;

----
--ST_Intersection
'''
ST_Clip zwraca raster
ST_Intersection zwraca zestaw par wartości geometria-piksel
ST_Intersection przekształca raster w wektor przed rzeczywistym „klipem” 
Zazwyczaj ST_Intersection jest wolniejsze od ST_Clip więc zasadnym jest
przeprowadzenie operacji ST_Clip na rastrze przed wykonaniem funkcji ST_Intersection
'''
CREATE TABLE schema_chmielarska.intersection AS
SELECT a.rid,(ST_Intersection(b.geom,a.rast)).geom,(ST_Intersection(b.geom,a.rast)).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ILIKE 'paranhos' AND ST_Intersects(b.geom,a.rast);

SELECT * FROM schema_chmielarska.intersection;

----
--ST_DumpAsPolygons->konwertuje rastry w wektory (poligony)
CREATE TABLE schema_chmielarska.dumppolygons AS
SELECT a.rid,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).geom,(ST_DumpAsPolygons(ST_Clip(a.rast,b.geom))).val
FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
WHERE b.parish ILIKE 'paranhos' AND ST_Intersects(b.geom,a.rast);

SELECT rid, ST_AsText(geom), val FROM schema_chmielarska.dumppolygons;

----
--ST_Band
CREATE TABLE schema_chmielarska.landsat_nir AS
SELECT rid, ST_Band(rast,4) AS rast --wyodrębnia 4 pasmo z obrazu rastrowego 
FROM rasters.landsat8;

SELECT * FROM schema_chmielarska.landsat_nir;

----
--ST_Clip--tutaj używany do wycięcia rastra z innego rastra, przycięcie rastra do granic geometrii paranhos
CREATE TABLE schema_chmielarska.paranhos_dem AS
SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE b.parish ILIKE 'paranhos' AND ST_Intersects(b.geom,a.rast);

CREATE INDEX idx_paranhos_dem_rast_gist ON schema_chmielarska.paranhos_dem
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'paranhos_dem'::name,'rast'::name);

SELECT * FROM schema_chmielarska.paranhos_dem;

----
--ST_Slope-oblicza nachylenie na podstawie różnicy wysokości między pikselami w sąsiedztwie
CREATE TABLE schema_chmielarska.paranhos_slope AS
SELECT a.rid,ST_Slope(a.rast,1,'32BF','PERCENTAGE') AS rast
FROM schema_chmielarska.paranhos_dem AS a;

CREATE INDEX idx_paranhos_slope_rast_gist ON schema_chmielarska.paranhos_slope
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'paranhos_slope'::name,'rast'::name);

SELECT * FROM schema_chmielarska.paranhos_slope;

----
--ST_Reclass--podział terenu na kategorie według % slope
CREATE TABLE schema_chmielarska.paranhos_slope_reclass AS
SELECT a.rid,ST_Reclass(a.rast,1,']0-15]:1, (15-30]:2, (30-9999:3','32BF',0) AS rast
-----------------------raster, pasmo, przedzialy
FROM schema_chmielarska.paranhos_slope AS a;

CREATE INDEX idx_paranhos_slope_reclass_rast_gist ON schema_chmielarska.paranhos_slope_reclass
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'paranhos_slope_reclass'::name,'rast'::name);

SELECT * FROM schema_chmielarska.paranhos_slope_reclass;

----
--ST_SummaryStat
SELECT ST_SummaryStats(a.rast) AS stats
FROM schema_chmielarska.paranhos_dem AS a;
--count,sum,mean,stddev,min,max

----
--ST_SummaryStats oraz Union
SELECT st_summarystats(ST_Union(a.rast))
FROM schema_chmielarska.paranhos_dem AS a;


----
--ST_SummaryStats z lepszą kontrolą złożonego typu danych
WITH t AS (
	SELECT ST_SummaryStats(ST_Union(a.rast)) AS stats
	FROM schema_chmielarska.paranhos_dem AS a
)
SELECT (stats).count,(stats).sum,(stats).mean,(stats).stddev,(stats).min,(stats).max FROM t

----
--ST_SummaryStats w połączeniu z GROUP BY
--statystyki z podziałem na parish
WITH t AS (
	SELECT b.parish AS parish, ST_SummaryStats(ST_Union(ST_Clip(a.rast,b.geom,true))) AS stats
	FROM rasters.dem AS a, vectors.porto_parishes AS b
	WHERE b.municipality ILIKE 'porto' AND ST_Intersects(b.geom,a.rast)
	GROUP BY b.parish
)
SELECT parish,(stats).min,(stats).max,(stats).mean FROM t;

----
--ST_Value-pozwala wyodrębnić wartość piksela z punktu lub zestawu punktów
--Przykład wyodrębnia punkty znajdujące się w tabeli vectors.places
--Geometria punktów jest wielopunktowa, a funkcja ST_Value wymaga geometrii
--jednopunktowej, należy przekonwertować geometrię wielopunktową na geometrię jednopunktową
--za pomocą funkcji (ST_Dump(b.geom)).geom.
SELECT b.name,st_value(a.rast,(ST_Dump(b.geom)).geom)
FROM rasters.dem a, vectors.places AS b
WHERE ST_Intersects(a.rast,b.geom)
ORDER BY b.name;

----
--TPI
'''
TPI porównuje wysokość każdej komórki w DEM ze średnią wysokością określonego sąsiedztwa
wokół tej komórki. Wartości dodatnie reprezentują lokalizacje, które są wyższe niż średnia ich
otoczenia, zgodnie z definicją sąsiedztwa (grzbietów).
'''
--ST_TPI
--ST_Value pozwala na utworzenie mapy TPI z DEM wysokości
CREATE TABLE schema_chmielarska.tpi30 AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem a;

CREATE INDEX idx_tpi30_rast_gist ON schema_chmielarska.tpi30
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'tpi30'::name,'rast'::name);


--ST_TPI dla Porto 
CREATE TABLE schema_chmielarska.tpi30_porto AS
SELECT ST_TPI(a.rast,1) AS rast
FROM rasters.dem AS a, vectors.porto_parishes AS b
WHERE ST_Intersects(a.rast,b.geom) AND b.municipality ILIKE 'porto';

CREATE INDEX idx_tpi30_porto_rast_gist ON schema_chmielarska.tpi30_porto
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'tpi30_porto'::name,'rast'::name);

----
--Wyrażenie Algebry Map
--użycie wyrażenia 
--NDVI=(NIR-Red)/(NIR+Red)
--NDVI (Normalized Difference Vegetation Index)
CREATE TABLE schema_chmielarska.porto_ndvi AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ILIKE 'porto' AND ST_Intersects(b.geom,a.rast)
)
SELECT r.rid,ST_MapAlgebra(
	r.rast, 1,
	r.rast, 4, 
	'([rast2.val] - [rast1.val]) / ([rast2.val] +[rast1.val])::float','32BF') AS rast
FROM r;

CREATE INDEX idx_porto_ndvi_rast_gist ON schema_chmielarska.porto_ndvi
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'porto_ndvi'::name,'rast'::name);

SELECT * FROM schema_chmielarska.porto_ndvi;

--funkcja zwrotna
CREATE OR REPLACE FUNCTION schema_chmielarska.ndvi(
	VALUE double precision [] [] [],
	pos integer [][],
	VARIADIC userargs text []
)
RETURNS double precision AS
$$
BEGIN
--RAISE NOTICE 'Pixel Value: %', value [1][1][1];-->For debug purposes
RETURN (value [2][1][1] - value [1][1][1])/(value [2][1][1]+value
[1][1][1]); --> NDVI calculation!
END;
$$
LANGUAGE 'plpgsql' IMMUTABLE COST 1000;

--wywołanie funkcji w query
CREATE TABLE schema_chmielarska.porto_ndvi2 AS
WITH r AS (
	SELECT a.rid,ST_Clip(a.rast, b.geom,true) AS rast
	FROM rasters.landsat8 AS a, vectors.porto_parishes AS b
	WHERE b.municipality ilike 'porto' and ST_Intersects(b.geom,a.rast)
)
SELECT r.rid,ST_MapAlgebra(
	r.rast, ARRAY[1,4],
	'schema_chmielarska.ndvi(double precision[],
	integer[],text[])'::regprocedure, --> This is the function!
	'32BF'::text
	) AS rast
FROM r;

CREATE INDEX idx_porto_ndvi2_rast_gist ON schema_chmielarska.porto_ndvi2
USING gist (ST_ConvexHull(rast));

SELECT AddRasterConstraints('schema_chmielarska'::name,
'porto_ndvi2'::name,'rast'::name);

SELECT * FROM schema_chmielarska.porto_ndvi2;

----
--ST_AsTiff
SELECT ST_AsTiff(ST_Union(rast))
FROM schema_chmielarska.porto_ndvi;

--ST_AsGDALRaster
SELECT ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])
FROM schema_chmielarska.porto_ndvi;


--large object
CREATE TABLE tmp_out AS
SELECT lo_from_bytea(0,
ST_AsGDALRaster(ST_Union(rast), 'GTiff', ARRAY['COMPRESS=DEFLATE','PREDICTOR=2', 'PZLEVEL=9'])) AS loid
FROM schema_chmielarska.porto_ndvi;
----------------------------------------------
SELECT lo_export(loid, 'C:\Users\zuzan\Desktop\sem7\Bazy Danych Przestrzennych\lab6\myraster.tiff') --> Save the file in a place where the user postgres have access. In windows a flash drive usualy works fine.
FROM tmp_out;
----------------------------------------------
SELECT lo_unlink(loid)
FROM tmp_out; --> Delete the large object.