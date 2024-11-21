-- View giving UFO / Turbine risk at H3 Resolution 6
CREATE VIEW ufo_turbine_risk_h3_r6 AS
WITH resolution AS (
    SELECT 6 AS h3_res
),
ufo_cell AS (
  SELECT count(*) AS cnt, 
        h3_lat_lng_to_cell(geom, r.h3_res ) AS cellid,
        ANY_VALUE(r.h3_res) As h3_res
	FROM us_ufo
    CROSS JOIN resolution r
    GROUP BY cellid
), 
turbine_cell AS (
  SELECT count(*) AS cnt, 
        h3_lat_lng_to_cell(geom, r.h3_res ) AS cellid
	FROM wind_turbines
    CROSS JOIN resolution r
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
)
SELECT ufo_count, turbine_count, 
        10000 * (ufo_count * turbine_count) / (area * area) AS risk, 
        cellid, h3_res, area,
        h3_cell_to_geometry( cellid )::geometry(Point, 4326) AS geom
    FROM cell;
