-- Given an tile index, generate the covering hexagons summarizing the UFO count,
-- and generate MVT output of the result. 
CREATE OR REPLACE
FUNCTION public.us_ufo_h3(z integer, x integer, y integer)
RETURNS bytea
AS $$
WITH
cell AS (
  SELECT count(*) AS ufo_count, h3_lat_lng_to_cell(geom,
                CASE WHEN z <= 2 THEN 2 ELSE z END
        ) AS cellid
	FROM us_ufo
	WHERE ST_Intersects(geom, 
                ST_Transform( ST_TileEnvelopeClip(z, x, y, margin => 0.125), 4326)
            )
    GROUP BY cellid
), 
feature AS (
    SELECT cellid, ufo_count, 
        h3_cell_area( cellid) AS area,
        round(1000 * ufo_count / h3_cell_area( cellid)) AS density,
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

