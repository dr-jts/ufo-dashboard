-- workaround for extent bug in ST_TileEnvelope function
CREATE OR REPLACE FUNCTION ST_TileEnvelopeClip(zoom integer, x integer, y integer, 
    bounds geometry 
              DEFAULT 'SRID=3857;LINESTRING(-20037508.342789244 -20037508.342789244, 20037508.342789244 20037508.342789244)'::geometry, 
    margin float8 DEFAULT 0.0)
	RETURNS geometry
AS $$
    SELECT ST_Intersection( ST_Envelope(bounds), ST_TileEnvelope(zoom, x, y, bounds, margin))
$$
LANGUAGE 'sql' STABLE STRICT PARALLEL SAFE;
