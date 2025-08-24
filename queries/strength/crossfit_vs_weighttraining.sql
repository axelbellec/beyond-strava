-- CrossFit vs Weight Training comparison analysis
-- Compares the two strength training modalities across various metrics
SELECT 
    'TRAINING COMPARISON' as analysis_type,
    sport_type,
    COUNT(*) as total_sessions,
    
    -- Duration analysis
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    ROUND(MIN(moving_time)/60, 1) as min_duration_min,
    ROUND(MAX(moving_time)/60, 1) as max_duration_min,
    ROUND(STDDEV(moving_time)/60, 1) as duration_consistency,
    
    -- Intensity analysis
    ROUND(AVG(suffer_score), 1) as avg_suffer_score,
    ROUND(MAX(suffer_score), 0) as max_suffer_score,
    ROUND(STDDEV(suffer_score), 1) as intensity_variation,
    
    -- Heart rate analysis
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(max_heartrate), 0) as avg_max_hr,
    ROUND(AVG(max_heartrate - average_heartrate), 0) as avg_hr_reserve,
    
    -- Training frequency
    ROUND(COUNT(*) * 365.0 / 
        (julianday('now') - julianday(MIN(start_date))), 1) as sessions_per_year,
    
    -- Recent activity (last 6 months)
    COUNT(CASE WHEN start_date >= date('now', '-6 months') THEN 1 END) as recent_sessions_6m,
    ROUND(AVG(CASE WHEN start_date >= date('now', '-6 months') 
                   THEN suffer_score END), 1) as recent_avg_intensity

FROM activities
WHERE sport_type IN ('Crossfit', 'WeightTraining')
AND start_date IS NOT NULL
AND moving_time > 0
GROUP BY sport_type

UNION ALL

SELECT 
    'MONTHLY TRENDS' as analysis_type,
    sport_type,
    NULL as total_sessions,
    NULL as avg_duration_min,
    NULL as min_duration_min,
    NULL as max_duration_min,
    NULL as duration_consistency,
    NULL as avg_suffer_score,
    NULL as max_suffer_score,
    NULL as intensity_variation,
    NULL as avg_hr,
    NULL as avg_max_hr,
    NULL as avg_hr_reserve,
    NULL as sessions_per_year,
    NULL as recent_sessions_6m,
    NULL as recent_avg_intensity
FROM activities WHERE 1=0  -- Empty result for separator

UNION ALL

SELECT 
    strftime('%Y-%m', start_date) as analysis_type,
    sport_type,
    COUNT(*) as total_sessions,
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    NULL as min_duration_min,
    NULL as max_duration_min,
    NULL as duration_consistency,
    ROUND(AVG(suffer_score), 1) as avg_suffer_score,
    ROUND(MAX(suffer_score), 0) as max_suffer_score,
    NULL as intensity_variation,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    NULL as avg_max_hr,
    NULL as avg_hr_reserve,
    NULL as sessions_per_year,
    NULL as recent_sessions_6m,
    NULL as recent_avg_intensity

FROM activities
WHERE sport_type IN ('Crossfit', 'WeightTraining')
AND start_date IS NOT NULL
AND moving_time > 0
AND start_date >= date('now', '-12 months')
GROUP BY strftime('%Y-%m', start_date), sport_type

ORDER BY analysis_type DESC, sport_type;