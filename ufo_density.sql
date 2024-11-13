-- Joins UFO H3 cells to Population cells to compute UFO density at H3 resolution 4 
CREATE OR REPLACE
FUNCTION public.us_ufo_density_r4(z integer, x integer, y integer)
RETURNS bytea
AS $$
-- Pre-calculate the tile envelope to avoid repeated calculations
WITH tile_env AS (
    SELECT ST_TileEnvelopeClip(z, x, y, margin => 0.125) AS env_geom
),
-- Set the H3 resolution based on zoom level
resolution AS (
    SELECT 4 AS h3_res
),
ufo_cell AS (
  SELECT count(*) AS cnt, 
        h3_lat_lng_to_cell(geom, r.h3_res ) AS cellid,
        ANY_VALUE(r.h3_res) As h3_res
	FROM us_ufo
    CROSS JOIN resolution r
	WHERE ST_Intersects(geom, ST_Transform((SELECT env_geom FROM tile_env), 4326))
    GROUP BY cellid
), 
cell AS (
    SELECT 
        u.cnt AS ufo_count,
        population,
        h3_cell_area( u.cellid ) AS area,    
        u.cellid,
        u.h3_res
    FROM ufo_cell u INNER JOIN kontur_population_r4 p ON u.cellid::varchar = p.h3
),
feature AS (
    SELECT ufo_count, population, 
        10000.0 * ufo_count / population AS density, 
        cellid, h3_res, area,
        ST_Transform( h3_cell_to_boundary_geometry( cellid ), 3857) AS geom
    FROM cell
),
-- Tile bounds in Web Mercator (3857)
bounds AS ( SELECT ST_TileEnvelope(z, x, y) AS geom ),
mvtgeom AS (
    -- Generate MVT-compatible geometry (quantize and clip to tile)
    SELECT ST_AsMVTGeom(feature.geom, bounds.geom) AS geom,
            cellid, h3_res,
            ROUND(density::numeric, 1)::numeric AS density,
            ufo_count,
            population,
            ROUND(area::numeric, 0) AS area       
    FROM feature, bounds
)
-- Generate MVT encoding of MVT features
SELECT ST_AsMVT(mvtgeom, 'us_ufo_density_r4') FROM mvtgeom
$$
LANGUAGE 'sql' STABLE STRICT PARALLEL SAFE;

COMMENT ON FUNCTION public.us_ufo_density_r4 IS 'US UFO sighting density as H3 cells.';
