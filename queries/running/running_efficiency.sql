-- Running efficiency and form analysis
-- Analyzes cadence, heart rate efficiency, and pace consistency
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    COUNT(*) as runs,
    
    -- Pace and efficiency metrics
    ROUND(AVG(CASE WHEN average_speed > 0 THEN 1000 / (average_speed * 60) ELSE NULL END), 2) as avg_pace_min_km,
    ROUND(STDDEV(CASE WHEN average_speed > 0 THEN 1000 / (average_speed * 60) ELSE NULL END), 2) as pace_consistency,
    
    -- Heart rate efficiency (lower HR at same pace = better fitness)
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(average_heartrate / NULLIF(average_speed * 3.6, 0)), 1) as hr_per_kmh,
    
    -- Cadence analysis (steps per minute)
    ROUND(AVG(average_cadence), 0) as avg_cadence_spm,
    
    -- Temperature impact
    ROUND(AVG(average_temp), 1) as avg_temp_c,
    
    -- Elevation and terrain impact
    ROUND(AVG(total_elevation_gain), 0) as avg_elevation_gain_m,
    ROUND(AVG(total_elevation_gain / NULLIF(distance, 0) * 1000), 1) as elevation_per_km,
    
    -- Recovery indicators
    ROUND(AVG(max_heartrate - average_heartrate), 0) as hr_reserve_avg,
    
    -- Distance distribution
    ROUND(AVG(distance)/1000, 2) as avg_distance_km,
    ROUND(MIN(distance)/1000, 2) as min_distance_km,
    ROUND(MAX(distance)/1000, 2) as max_distance_km

FROM activities
WHERE sport_type IN ('Run', 'TrailRun')
AND distance > 1000
AND average_speed > 0
AND start_date IS NOT NULL
GROUP BY month, sport_type
ORDER BY month DESC, sport_type;