-- Fitness progression and trends analysis
-- Tracks improvements in aerobic fitness, speed, and endurance over time
WITH monthly_fitness AS (
    SELECT 
        strftime('%Y-%m', start_date) as month,
        sport_type,
        COUNT(*) as runs,
        
        -- Aerobic fitness indicators
        ROUND(AVG(average_heartrate), 0) as avg_hr,
        ROUND(AVG(CASE WHEN average_speed > 0 THEN 1000 / (average_speed * 60) ELSE NULL END), 2) as avg_pace_min_km,
        ROUND(AVG(average_heartrate / NULLIF(average_speed * 3.6, 0)), 1) as aerobic_efficiency,
        
        -- Endurance indicators
        ROUND(AVG(distance)/1000, 2) as avg_distance_km,
        ROUND(AVG(moving_time)/60, 1) as avg_duration_min,
        ROUND(MAX(distance)/1000, 2) as longest_run_km,
        
        -- Recovery and adaptation
        ROUND(AVG(max_heartrate - average_heartrate), 0) as hr_reserve,
        ROUND(AVG(suffer_score), 1) as avg_suffer_score,
        
        -- Training load
        ROUND(SUM(distance)/1000, 1) as monthly_volume_km,
        ROUND(SUM(moving_time)/3600, 1) as monthly_hours,
        ROUND(SUM(total_elevation_gain), 0) as monthly_elevation_m
        
    FROM activities
    WHERE sport_type IN ('Run', 'TrailRun')
    AND distance > 1000
    AND average_speed > 0
    AND has_heartrate = true
    AND start_date IS NOT NULL
    GROUP BY month, sport_type
),
fitness_trends AS (
    SELECT *,
        -- Calculate 3-month rolling averages for trend analysis
        AVG(avg_pace_min_km) OVER (
            PARTITION BY sport_type 
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as pace_trend_3m,
        AVG(aerobic_efficiency) OVER (
            PARTITION BY sport_type 
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as efficiency_trend_3m,
        AVG(monthly_volume_km) OVER (
            PARTITION BY sport_type 
            ORDER BY month 
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ) as volume_trend_3m
    FROM monthly_fitness
)
SELECT 
    month,
    sport_type,
    runs,
    
    -- Current month metrics
    avg_pace_min_km as current_pace,
    aerobic_efficiency as current_efficiency,
    monthly_volume_km as current_volume,
    
    -- Trend indicators (3-month rolling average)
    ROUND(pace_trend_3m, 2) as pace_trend_3m,
    ROUND(efficiency_trend_3m, 1) as efficiency_trend_3m,
    ROUND(volume_trend_3m, 1) as volume_trend_3m,
    
    -- Performance indicators
    longest_run_km,
    avg_hr,
    hr_reserve,
    
    -- Training load
    monthly_hours,
    monthly_elevation_m,
    avg_suffer_score

FROM fitness_trends
ORDER BY month DESC, sport_type;