-- Given a tile index, clusters UFO points by H3 cells at zoom-based resolution,
-- and generate MVT output. 
CREATE OR REPLACE
FUNCTION public.us_ufo_h3_cluster(z integer, x integer, y integer)
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
        WHEN z <= 2 THEN 0
        WHEN z <= 3 THEN 1
        WHEN z <= 4 THEN 2
        WHEN z <= 6 THEN 3
        WHEN z <= 8 THEN 4
        WHEN z <= 10 THEN 5
                    ELSE 6
    END AS h3_res
),
cell AS (
  SELECT count(*) AS ufo_count, 
        ST_Transform( ANY_VALUE(geom), 3857) AS geom, 
        ANY_VALUE(state) AS state,
        h3_lat_lng_to_cell(geom, (SELECT h3_res FROM resolution)) AS cellid
	FROM us_ufo
	WHERE ST_Intersects(geom, (SELECT env_geom FROM tile_env))
    GROUP BY cellid
), 
-- Tile bounds in Web Mercator (3857)
bounds AS ( SELECT ST_TileEnvelope(z, x, y) AS geom ),
mvtgeom AS (
    -- Generate MVT-compatible geometry (quantize and clip to tile)
    SELECT ST_AsMVTGeom(cell.geom, bounds.geom) AS geom,
           cellid, ufo_count, state
    FROM cell, bounds
)
-- Generate MVT encoding of MVT features
SELECT ST_AsMVT(mvtgeom, 'default') FROM mvtgeom
$$
LANGUAGE 'sql' STABLE STRICT PARALLEL SAFE;

COMMENT ON FUNCTION public.us_ufo_h3_cluster IS 'US UFO sightings clustered by H3 cells.';
