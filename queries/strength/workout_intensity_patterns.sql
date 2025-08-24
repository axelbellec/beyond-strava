-- Workout intensity and effort patterns
-- Analyzes intensity distribution and recovery patterns for strength training
WITH intensity_categories AS (
    SELECT *,
        CASE 
            WHEN suffer_score IS NULL OR suffer_score = 0 THEN 'No Data'
            WHEN suffer_score < 20 THEN 'Light (< 20)'
            WHEN suffer_score < 50 THEN 'Moderate (20-50)'
            WHEN suffer_score < 80 THEN 'Hard (50-80)'
            WHEN suffer_score < 120 THEN 'Very Hard (80-120)'
            ELSE 'Extreme (> 120)'
        END as intensity_level,
        CASE 
            WHEN moving_time < 1800 THEN 'Short (< 30min)'
            WHEN moving_time < 3600 THEN 'Medium (30-60min)'
            ELSE 'Long (> 60min)'
        END as duration_category
    FROM activities
    WHERE sport_type IN ('Crossfit', 'WeightTraining')
    AND start_date IS NOT NULL
    AND moving_time > 0
)
SELECT 
    sport_type,
    intensity_level,
    duration_category,
    COUNT(*) as sessions,
    ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
    ROUND(AVG(suffer_score), 1) as avg_suffer_score,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(max_heartrate), 0) as avg_max_hr,
    
    -- Heart rate intensity analysis
    ROUND(AVG(CASE WHEN max_heartrate > 0 AND average_heartrate > 0 
                   THEN (average_heartrate * 1.0 / max_heartrate) * 100 
                   ELSE NULL END), 1) as avg_hr_intensity_pct,
    
    -- Recent trend (last 3 months)
    COUNT(CASE WHEN start_date >= date('now', '-3 months') THEN 1 END) as recent_sessions,
    ROUND(AVG(CASE WHEN start_date >= date('now', '-3 months') 
                   THEN suffer_score END), 1) as recent_avg_suffer_score

FROM intensity_categories
WHERE intensity_level != 'No Data'
GROUP BY sport_type, intensity_level, duration_category
ORDER BY sport_type, 
    CASE intensity_level
        WHEN 'Light (< 20)' THEN 1
        WHEN 'Moderate (20-50)' THEN 2
        WHEN 'Hard (50-80)' THEN 3
        WHEN 'Very Hard (80-120)' THEN 4
        ELSE 5
    END,
    duration_category;