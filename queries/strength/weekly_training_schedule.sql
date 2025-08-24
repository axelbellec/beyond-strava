-- Weekly training schedule and day-of-week patterns
-- Analyzes which days you prefer for strength training and performance by day
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
    COUNT(*) as sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY sport_type), 1) as percentage_of_sessions,
    
    -- Performance by day
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    ROUND(AVG(suffer_score), 1) as avg_suffer_score,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    
    -- Session timing patterns
    ROUND(AVG(CASE WHEN strftime('%H', start_date_local) < '12' THEN 1.0 ELSE 0.0 END) * 100, 1) as morning_sessions_pct,
    ROUND(AVG(CASE WHEN strftime('%H', start_date_local) BETWEEN '12' AND '17' THEN 1.0 ELSE 0.0 END) * 100, 1) as afternoon_sessions_pct,
    ROUND(AVG(CASE WHEN strftime('%H', start_date_local) >= '18' THEN 1.0 ELSE 0.0 END) * 100, 1) as evening_sessions_pct,
    
    -- Consistency indicators
    MIN(start_date) as first_session,
    MAX(start_date) as last_session,
    
    -- Best performance day indicators
    MAX(suffer_score) as max_suffer_score,
    MAX(moving_time) as longest_session_min

FROM activities
WHERE sport_type IN ('Crossfit', 'WeightTraining')
AND start_date IS NOT NULL
AND start_date_local IS NOT NULL
AND moving_time > 0
GROUP BY day_of_week, day_name, sport_type
ORDER BY sport_type, day_of_week;