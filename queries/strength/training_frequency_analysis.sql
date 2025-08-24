-- Strength training frequency and consistency analysis
-- Tracks CrossFit and Weight Training patterns over time
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    COUNT(*) as sessions,
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    ROUND(SUM(moving_time)/3600, 2) as total_hours,
    ROUND(AVG(suffer_score), 1) as avg_suffer_score,
    ROUND(MAX(suffer_score), 0) as max_suffer_score,
    
    -- Weekly frequency indicators
    ROUND(COUNT(*) * 7.0 / 
        (julianday(MAX(start_date)) - julianday(MIN(start_date)) + 1), 1) as sessions_per_week,
    
    -- Consistency metrics
    COUNT(DISTINCT strftime('%W', start_date)) as weeks_trained,
    ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT strftime('%W', start_date)), 1) as avg_sessions_per_week_actual,
    
    -- Duration distribution
    COUNT(CASE WHEN moving_time < 1800 THEN 1 END) as short_sessions_under_30min,
    COUNT(CASE WHEN moving_time BETWEEN 1800 AND 3600 THEN 1 END) as medium_sessions_30_60min,
    COUNT(CASE WHEN moving_time > 3600 THEN 1 END) as long_sessions_over_60min

FROM activities
WHERE sport_type IN ('Crossfit', 'WeightTraining')
AND start_date IS NOT NULL
AND moving_time > 0
GROUP BY month, sport_type
ORDER BY month DESC, sport_type;