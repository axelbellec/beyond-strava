-- Heart rate training zones analysis
-- Analyzes training intensity distribution and aerobic fitness trends
WITH hr_zones AS (
    SELECT *,
        CASE 
            WHEN average_heartrate < 130 THEN 'Zone 1 (Recovery < 130)'
            WHEN average_heartrate < 145 THEN 'Zone 2 (Aerobic 130-145)'
            WHEN average_heartrate < 160 THEN 'Zone 3 (Tempo 145-160)'
            WHEN average_heartrate < 175 THEN 'Zone 4 (Threshold 160-175)'
            ELSE 'Zone 5 (VO2Max > 175)'
        END as hr_zone,
        -- Convert m/s to min/km pace
        CASE WHEN average_speed > 0 
             THEN ROUND(1000 / (average_speed * 60), 2) 
             ELSE NULL 
        END as pace_min_per_km
    FROM activities
    WHERE sport_type IN ('Run', 'TrailRun')
    AND has_heartrate = true
    AND average_heartrate > 100  -- Filter realistic HR values
    AND distance > 1000
)
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    hr_zone,
    COUNT(*) as runs,
    ROUND(SUM(moving_time)/3600, 2) as total_hours,
    ROUND(AVG(pace_min_per_km), 2) as avg_pace_min_km,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(max_heartrate), 0) as avg_max_hr,
    ROUND(AVG(distance)/1000, 2) as avg_distance_km,
    -- Efficiency metrics
    ROUND(AVG(distance / moving_time * 3.6), 2) as avg_speed_kmh,
    ROUND(AVG(total_elevation_gain), 0) as avg_elevation_m
FROM hr_zones
WHERE pace_min_per_km BETWEEN 3 AND 12
GROUP BY month, sport_type, hr_zone
ORDER BY month DESC, sport_type, 
    CASE hr_zone
        WHEN 'Zone 1 (Recovery < 130)' THEN 1
        WHEN 'Zone 2 (Aerobic 130-145)' THEN 2
        WHEN 'Zone 3 (Tempo 145-160)' THEN 3
        WHEN 'Zone 4 (Threshold 160-175)' THEN 4
        ELSE 5
    END;