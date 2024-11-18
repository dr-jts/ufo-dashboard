-- Given a tile index, generate UFO/turbine risk as H3 cells,
-- and generate MVT output of the result. 
CREATE OR REPLACE
FUNCTION public.us_ufo_turbine_h3(z integer, x integer, y integer)
RETURNS bytea
AS $$
-- Pre-calculate the tile envelope to avoid repeated calculations
WITH tile_env AS (
   SELECT ST_Transform(ST_TileEnvelopeClip(z, x, y, margin => 0.125), 4326) AS env_geom
),
-- Calculate the H3 resolution based on zoom level
resolution AS (
    SELECT CASE
        WHEN z <= 2 THEN 2
        WHEN z <= 4 THEN 3
        WHEN z <= 6 THEN 4
        WHEN z <= 8 THEN 5
        ELSE 6
    END AS h3_res
),
ufo_cell AS (
  SELECT count(*) AS cnt, 
        h3_lat_lng_to_cell(geom, r.h3_res ) AS cellid,
        ANY_VALUE(r.h3_res) As h3_res
	FROM us_ufo
    CROSS JOIN resolution r
	WHERE ST_Intersects(geom, (SELECT env_geom FROM tile_env))
    GROUP BY cellid
), 
turbine_cell AS (
  SELECT count(*) AS cnt, 
        h3_lat_lng_to_cell(geom, r.h3_res ) AS cellid
	FROM wind_turbines
    CROSS JOIN resolution r
	WHERE ST_Intersects(geom, (SELECT env_geom FROM tile_env))
    GROUP BY cellid
),
cell AS (
    SELECT 
        u.cnt AS ufo_count,
        t.cnt AS turbine_count,
        h3_cell_area( u.cellid) AS area,    
        u.cellid,
        u.h3_res
    FROM ufo_cell u INNER JOIN turbine_cell t ON u.cellid = t.cellid
),
feature AS (
    SELECT ufo_count, turbine_count, 
        10000 * (ufo_count * turbine_count) / (area * area) AS risk, 
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
            ROUND(risk::numeric, 1) AS risk,
            ufo_count,
            turbine_count,
            ROUND(area::numeric, 0) AS area       
    FROM feature, bounds
)
-- Generate MVT encoding of MVT features
SELECT ST_AsMVT(mvtgeom, 'us_ufo_turbine_h3') FROM mvtgeom
$$
LANGUAGE 'sql' STABLE STRICT PARALLEL SAFE;

COMMENT ON FUNCTION public.us_ufo_turbine_h3 IS 'Risk of UFO-wind turbine collision as H3 cells.';


