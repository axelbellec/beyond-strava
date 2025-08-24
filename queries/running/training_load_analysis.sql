-- Training load analysis for running activities
-- Analyzes volume, intensity, and training stress over time
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    COUNT(*) as runs,
    ROUND(SUM(distance)/1000, 2) as total_km,
    ROUND(AVG(distance)/1000, 2) as avg_distance_km,
    ROUND(SUM(moving_time)/3600, 2) as total_hours,
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    ROUND(AVG(average_speed * 3.6), 2) as avg_pace_kmh,
    ROUND(AVG(total_elevation_gain), 0) as avg_elevation_m,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    -- Training load indicators
    ROUND(SUM(distance * total_elevation_gain / 1000), 0) as elevation_adjusted_km,
    ROUND(SUM(suffer_score), 0) as total_suffer_score,
    ROUND(AVG(suffer_score), 1) as avg_suffer_score
FROM activities
WHERE sport_type IN ('Run', 'TrailRun') 
AND start_date IS NOT NULL
AND distance > 1000  -- Filter out very short activities
GROUP BY month, sport_type
ORDER BY month DESC, sport_type;