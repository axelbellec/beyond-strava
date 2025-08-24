-- Elevation analysis
SELECT 
    sport_type,
    COUNT(*) as activities,
    ROUND(AVG(total_elevation_gain), 1) as avg_elevation_m,
    MAX(total_elevation_gain) as max_elevation_m,
    ROUND(AVG(elev_high - elev_low), 1) as avg_elevation_range_m
FROM activities
WHERE total_elevation_gain IS NOT NULL
GROUP BY sport_type
ORDER BY avg_elevation_m DESC;