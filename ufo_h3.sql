-- Given an tile index, generate the covering hexagons summarizing the UFO count,
-- and generate MVT output of the result. 
CREATE OR REPLACE
FUNCTION public.us_ufo_h3(z integer, x integer, y integer)
RETURNS bytea
AS $$
WITH
-- Pre-calculate the tile envelope to avoid repeated calculations
tile_env AS (
    SELECT ST_Transform(ST_TileEnvelopeClip(z, x, y, margin => 0.125), 4326) AS env_geom
),
-- Calculate the H3 resolution based on zoom level
resolution AS (
    SELECT CASE
        WHEN z <= 2 THEN 2
        WHEN z <= 5 THEN z
        ELSE 6
    END AS h3_res
),
cell AS (
  SELECT count(*) AS ufo_count, 
        h3_lat_lng_to_cell(geom, (SELECT h3_res FROM resolution) ) AS cellid
	FROM us_ufo
	WHERE ST_Intersects(geom, (SELECT env_geom FROM tile_env))
    GROUP BY cellid
), 
feature AS (
    SELECT cellid, ufo_count, 
        round(1000 * ufo_count / h3_cell_area( cellid)) AS density,
        h3_cell_area( cellid) AS area,
        ST_Transform( h3_cell_to_boundary_geometry( cellid ), 3857) AS geom
    FROM cell
),
-- Tile bounds in Web Mercator (3857)
bounds AS ( SELECT ST_TileEnvelope(z, x, y) AS geom ),
mvtgeom AS (
    -- Generate MVT-compatible geometry (quantize and clip to tile)
    SELECT ST_AsMVTGeom(feature.geom, bounds.geom) AS geom,
           cellid, ufo_count, area, density
    FROM feature, bounds
)
-- Generate MVT encoding of MVT features
SELECT ST_AsMVT(mvtgeom, 'default') FROM mvtgeom
$$
LANGUAGE 'sql' STABLE STRICT PARALLEL SAFE;

COMMENT ON FUNCTION public.us_ufo_h3 IS 'Summary of US UFO sighting points as H3 cells.';

