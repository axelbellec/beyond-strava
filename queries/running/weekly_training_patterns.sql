-- Weekly training patterns and consistency
-- Analyzes which days you run most and training consistency
SELECT 
    strftime('%w', start_date) as day_of_week,
    CASE strftime('%w', start_date)
        WHEN '0' THEN 'Sunday'
        WHEN '1' THEN 'Monday' 
        WHEN '2' THEN 'Tuesday'
        WHEN '3' THEN 'Wednesday'
        WHEN '4' THEN 'Thursday'
        WHEN '5' THEN 'Friday'
        WHEN '6' THEN 'Saturday'
    END as day_name,
    sport_type,
    COUNT(*) as runs,
    ROUND(AVG(distance)/1000, 2) as avg_distance_km,
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    ROUND(AVG(CASE WHEN average_speed > 0 THEN 1000 / (average_speed * 60) ELSE NULL END), 2) as avg_pace_min_km,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(total_elevation_gain), 0) as avg_elevation_m,
    
    -- Performance by day patterns
    ROUND(MIN(CASE WHEN average_speed > 0 THEN 1000 / (average_speed * 60) ELSE NULL END), 2) as best_pace_min_km,
    ROUND(MAX(distance)/1000, 2) as longest_run_km,
    
    -- Training intensity by day
    ROUND(AVG(suffer_score), 1) as avg_suffer_score

FROM activities
WHERE sport_type IN ('Run', 'TrailRun')
AND distance > 1000
AND start_date IS NOT NULL
GROUP BY day_of_week, day_name, sport_type
ORDER BY day_of_week, sport_type;