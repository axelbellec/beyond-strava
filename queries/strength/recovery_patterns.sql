-- Recovery patterns and training density analysis
-- Analyzes rest days, training frequency, and recovery indicators
WITH session_gaps AS (
    SELECT 
        sport_type,
        start_date,
        moving_time,
        suffer_score,
        average_heartrate,
        max_heartrate,
        LAG(start_date) OVER (PARTITION BY sport_type ORDER BY start_date) as prev_session_date,
        LAG(suffer_score) OVER (PARTITION BY sport_type ORDER BY start_date) as prev_suffer_score
    FROM activities
    WHERE sport_type IN ('Crossfit', 'WeightTraining')
    AND start_date IS NOT NULL
    AND moving_time > 0
),
recovery_analysis AS (
    SELECT *,
        CASE WHEN prev_session_date IS NOT NULL 
             THEN julianday(start_date) - julianday(prev_session_date)
             ELSE NULL 
        END as days_since_last_session,
        CASE 
            WHEN prev_session_date IS NULL THEN NULL
            WHEN julianday(start_date) - julianday(prev_session_date) = 1 THEN 'Back-to-back'
            WHEN julianday(start_date) - julianday(prev_session_date) <= 2 THEN '1 day rest'
            WHEN julianday(start_date) - julianday(prev_session_date) <= 3 THEN '2 days rest'
            WHEN julianday(start_date) - julianday(prev_session_date) <= 7 THEN '3-6 days rest'
            ELSE '7+ days rest'
        END as recovery_category
    FROM session_gaps
)
SELECT 
    sport_type,
    recovery_category,
    COUNT(*) as sessions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY sport_type), 1) as percentage,
    
    -- Performance after different recovery periods
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    ROUND(AVG(suffer_score), 1) as avg_suffer_score,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(max_heartrate), 0) as avg_max_hr,
    
    -- Recovery effectiveness indicators
    ROUND(AVG(days_since_last_session), 1) as avg_rest_days,
    ROUND(AVG(CASE WHEN prev_suffer_score IS NOT NULL 
                   THEN suffer_score - prev_suffer_score 
                   ELSE NULL END), 1) as avg_intensity_change,
    
    -- Heart rate recovery indicators
    ROUND(AVG(max_heartrate - average_heartrate), 0) as avg_hr_reserve,
    
    -- Performance consistency after recovery
    ROUND(STDDEV(suffer_score), 1) as intensity_consistency

FROM recovery_analysis
WHERE recovery_category IS NOT NULL
GROUP BY sport_type, recovery_category
ORDER BY sport_type, 
    CASE recovery_category
        WHEN 'Back-to-back' THEN 1
        WHEN '1 day rest' THEN 2
        WHEN '2 days rest' THEN 3
        WHEN '3-6 days rest' THEN 4
        ELSE 5
    END;