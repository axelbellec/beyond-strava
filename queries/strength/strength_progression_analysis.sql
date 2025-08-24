-- Strength training progression and adaptation analysis
-- Tracks improvements in training capacity, recovery, and consistency over time
WITH monthly_progression AS (
    SELECT 
        strftime('%Y-%m', start_date) as month,
        sport_type,
        COUNT(*) as sessions,
        ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
        ROUND(AVG(suffer_score), 1) as avg_suffer_score,
        ROUND(AVG(average_heartrate), 0) as avg_hr,
        ROUND(AVG(max_heartrate), 0) as avg_max_hr,
        
        -- Training load indicators
        ROUND(SUM(moving_time)/3600, 2) as monthly_hours,
        ROUND(SUM(suffer_score), 0) as monthly_suffer_score,
        ROUND(MAX(suffer_score), 0) as peak_intensity,
        
        -- Recovery and adaptation metrics
        ROUND(AVG(max_heartrate - average_heartrate), 0) as avg_hr_reserve,
        ROUND(STDDEV(suffer_score), 1) as intensity_variation,
        
        -- Consistency metrics
        COUNT(DISTINCT strftime('%W', start_date)) as weeks_active,
        ROUND(COUNT(*) * 1.0 / COUNT(DISTINCT strftime('%W', start_date)), 1) as sessions_per_week
        
    FROM activities
    WHERE sport_type IN ('Crossfit', 'WeightTraining')
    AND start_date IS NOT NULL
    AND moving_time > 0
    GROUP BY month, sport_type
)
SELECT 
    month,
    sport_type,
    sessions,
    sessions_per_week,
    
    -- Current month metrics
    avg_duration_min,
    avg_suffer_score,
    monthly_hours,
    peak_intensity,
    
    -- Progression indicators (compare to 3-month average)
    ROUND(AVG(avg_suffer_score) OVER (
        PARTITION BY sport_type 
        ORDER BY month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1) as suffer_score_3m_avg,
    
    ROUND(AVG(avg_duration_min) OVER (
        PARTITION BY sport_type 
        ORDER BY month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1) as duration_3m_avg,
    
    ROUND(AVG(sessions_per_week) OVER (
        PARTITION BY sport_type 
        ORDER BY month 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 1) as frequency_3m_avg,
    
    -- Recovery indicators
    avg_hr,
    avg_hr_reserve,
    intensity_variation,
    
    -- Training capacity trends
    monthly_suffer_score,
    weeks_active

FROM monthly_progression
ORDER BY month DESC, sport_type;