-- Pace progression analysis
-- Tracks running pace improvements over time by distance categories
WITH distance_categories AS (
    SELECT *,
        CASE 
            WHEN distance < 5000 THEN 'Short (< 5km)'
            WHEN distance < 10000 THEN 'Medium (5-10km)'
            WHEN distance < 21100 THEN 'Long (10-21km)'
            ELSE 'Ultra (> 21km)'
        END as distance_category,
        -- Convert m/s to min/km pace
        CASE WHEN average_speed > 0 
             THEN ROUND(1000 / (average_speed * 60), 2) 
             ELSE NULL 
        END as pace_min_per_km
    FROM activities
    WHERE sport_type IN ('Run', 'TrailRun')
    AND distance > 1000
    AND average_speed > 0
)
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    distance_category,
    COUNT(*) as runs,
    ROUND(AVG(pace_min_per_km), 2) as avg_pace_min_km,
    ROUND(MIN(pace_min_per_km), 2) as best_pace_min_km,
    ROUND(MAX(pace_min_per_km), 2) as slowest_pace_min_km,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(total_elevation_gain), 0) as avg_elevation_m
FROM distance_categories
WHERE pace_min_per_km BETWEEN 3 AND 12  -- Filter realistic paces
GROUP BY month, sport_type, distance_category
ORDER BY month DESC, sport_type, distance_category;