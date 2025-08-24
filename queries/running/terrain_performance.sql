-- Terrain and elevation performance analysis
-- Compares road vs trail performance and elevation impact
WITH terrain_analysis AS (
    SELECT *,
        CASE WHEN average_speed > 0 
             THEN ROUND(1000 / (average_speed * 60), 2) 
             ELSE NULL 
        END as pace_min_per_km,
        CASE 
            WHEN total_elevation_gain < 50 THEN 'Flat (< 50m)'
            WHEN total_elevation_gain < 150 THEN 'Rolling (50-150m)'
            WHEN total_elevation_gain < 300 THEN 'Hilly (150-300m)'
            WHEN total_elevation_gain < 500 THEN 'Very Hilly (300-500m)'
            ELSE 'Mountainous (> 500m)'
        END as terrain_type,
        ROUND(total_elevation_gain / (distance / 1000), 1) as elevation_per_km
    FROM activities
    WHERE sport_type IN ('Run', 'TrailRun')
    AND distance > 1000
    AND average_speed > 0
    AND start_date IS NOT NULL
)
SELECT 
    sport_type,
    terrain_type,
    COUNT(*) as runs,
    
    -- Performance metrics
    ROUND(AVG(pace_min_per_km), 2) as avg_pace_min_km,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(distance)/1000, 2) as avg_distance_km,
    
    -- Elevation impact
    ROUND(AVG(total_elevation_gain), 0) as avg_elevation_gain_m,
    ROUND(AVG(elevation_per_km), 1) as avg_elevation_per_km,
    
    -- Effort analysis
    ROUND(AVG(average_heartrate / NULLIF(average_speed * 3.6, 0)), 1) as hr_per_kmh_effort,
    ROUND(AVG(suffer_score), 1) as avg_suffer_score,
    
    -- Performance range
    ROUND(MIN(pace_min_per_km), 2) as best_pace_min_km,
    ROUND(MAX(pace_min_per_km), 2) as slowest_pace_min_km,
    
    -- Recent trend (last 6 months)
    ROUND(AVG(CASE WHEN start_date >= date('now', '-6 months') THEN pace_min_per_km END), 2) as recent_avg_pace

FROM terrain_analysis
WHERE pace_min_per_km BETWEEN 3 AND 12
GROUP BY sport_type, terrain_type
ORDER BY sport_type, 
    CASE terrain_type
        WHEN 'Flat (< 50m)' THEN 1
        WHEN 'Rolling (50-150m)' THEN 2
        WHEN 'Hilly (150-300m)' THEN 3
        WHEN 'Very Hilly (300-500m)' THEN 4
        ELSE 5
    END;