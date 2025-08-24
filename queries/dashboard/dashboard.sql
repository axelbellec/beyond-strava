-- ============================================================
-- Beyond Strava - Personal Training Dashboard
-- ============================================================
-- This file contains pre-built dashboard queries for comprehensive 
-- training analysis using the DuckDB UI.
-- 
-- Usage: Open this file in the DuckDB UI after running analyze.py
-- Launch: duckdb -ui strava_activities.duckdb
-- ============================================================

-- ============================================================
-- TRAINING OVERVIEW
-- ============================================================

-- Quick Training Summary (Current Week vs Last Week)
SELECT 
    'This Week' as period,
    activities_this_week as activities,
    km_this_week as km,
    hours_this_week as hours,
    avg_intensity_this_week as avg_intensity
FROM dashboard_metrics
UNION ALL
SELECT 
    'Last Week' as period,
    activities_last_week as activities,
    km_last_week as km,
    hours_last_week as hours,
    avg_intensity_last_week as avg_intensity
FROM dashboard_metrics
UNION ALL
SELECT 
    'This Month' as period,
    activities_this_month as activities,
    km_this_month as km,
    hours_this_month as hours,
    NULL as avg_intensity
FROM dashboard_metrics;

-- Week-over-Week Performance Changes
SELECT 
    'Activities' as metric,
    activities_change_pct as change_percentage,
    CASE 
        WHEN activities_change_pct > 0 THEN 'Increased'
        WHEN activities_change_pct < 0 THEN 'Decreased'
        ELSE 'Unchanged'
    END as trend
FROM dashboard_metrics
UNION ALL
SELECT 
    'Distance (km)' as metric,
    km_change_pct as change_percentage,
    CASE 
        WHEN km_change_pct > 0 THEN 'Increased'
        WHEN km_change_pct < 0 THEN 'Decreased'
        ELSE 'Unchanged'
    END as trend
FROM dashboard_metrics
UNION ALL
SELECT 
    'Hours' as metric,
    hours_change_pct as change_percentage,
    CASE 
        WHEN hours_change_pct > 0 THEN 'Increased'
        WHEN hours_change_pct < 0 THEN 'Decreased'
        ELSE 'Unchanged'
    END as trend
FROM dashboard_metrics;

-- ============================================================
-- TRAINING TRENDS (Last 12 Weeks)
-- ============================================================

-- Weekly Training Volume by Sport
SELECT * FROM v_weekly_summary 
ORDER BY week DESC 
LIMIT 12;

-- Monthly Training Trends
SELECT 
    month,
    sport_type,
    activities,
    total_km,
    total_hours,
    avg_hr
FROM v_monthly_trends 
WHERE month >= strftime('%Y-%m', current_date - INTERVAL '6 months')
ORDER BY month DESC, sport_type;

-- ============================================================
-- RUNNING PERFORMANCE
-- ============================================================

-- Running Pace Trends (Recent 3 Months)
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    COUNT(*) as runs,
    ROUND(AVG(CASE WHEN average_speed > 0 
                   THEN 1000 / (average_speed * 60) 
                   ELSE NULL END), 2) as avg_pace_min_km,
    ROUND(MIN(CASE WHEN average_speed > 0 
                   THEN 1000 / (average_speed * 60) 
                   ELSE NULL END), 2) as best_pace_min_km,
    ROUND(AVG(average_heartrate), 0) as avg_hr,
    ROUND(AVG(distance/1000), 2) as avg_distance_km
FROM activities 
WHERE sport_type IN ('Run', 'TrailRun')
AND start_date >= current_date - INTERVAL '3 months'
AND average_speed > 0
AND distance > 1000
GROUP BY month, sport_type
ORDER BY month DESC, sport_type;

-- Heart Rate Zones Distribution (Running)
SELECT 
    sport_type,
    CASE 
        WHEN average_heartrate < 130 THEN 'Zone 1 (Recovery < 130)'
        WHEN average_heartrate < 145 THEN 'Zone 2 (Aerobic 130-145)'
        WHEN average_heartrate < 160 THEN 'Zone 3 (Tempo 145-160)'
        WHEN average_heartrate < 175 THEN 'Zone 4 (Threshold 160-175)'
        ELSE 'Zone 5 (VO2Max > 175)'
    END as hr_zone,
    COUNT(*) as runs,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY sport_type), 1) as percentage,
    ROUND(AVG(distance/1000), 2) as avg_distance_km
FROM activities 
WHERE sport_type IN ('Run', 'TrailRun')
AND has_heartrate = true
AND average_heartrate > 100
AND start_date >= current_date - INTERVAL '6 months'
GROUP BY sport_type, hr_zone
ORDER BY sport_type, 
    CASE hr_zone
        WHEN 'Zone 1 (Recovery < 130)' THEN 1
        WHEN 'Zone 2 (Aerobic 130-145)' THEN 2
        WHEN 'Zone 3 (Tempo 145-160)' THEN 3
        WHEN 'Zone 4 (Threshold 160-175)' THEN 4
        ELSE 5
    END;

-- ============================================================
-- STRENGTH TRAINING ANALYSIS
-- ============================================================

-- Strength Training Frequency
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    COUNT(*) as sessions,
    ROUND(AVG(moving_time/60), 1) as avg_duration_min,
    ROUND(AVG(suffer_score), 1) as avg_intensity,
    -- Sessions per week calculation
    ROUND(COUNT(*) * 7.0 / 
        (date_diff('day', MIN(start_date), MAX(start_date)) + 1), 1) as sessions_per_week
FROM activities 
WHERE sport_type IN ('Crossfit', 'WeightTraining')
AND start_date >= current_date - INTERVAL '6 months'
GROUP BY month, sport_type
ORDER BY month DESC, sport_type;

-- Weekly Training Schedule (Best Days)
SELECT 
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
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY sport_type), 1) as percentage,
    ROUND(AVG(moving_time/60), 1) as avg_duration_min,
    ROUND(AVG(suffer_score), 1) as avg_intensity
FROM activities 
WHERE sport_type IN ('Crossfit', 'WeightTraining')
AND start_date >= current_date - INTERVAL '6 months'
GROUP BY strftime('%w', start_date), day_name, sport_type
ORDER BY sport_type, strftime('%w', start_date);

-- ============================================================
-- PERSONAL RECORDS & ACHIEVEMENTS
-- ============================================================

-- Recent Personal Records (Last 6 Months)
SELECT * FROM v_personal_records
WHERE start_date >= current_date - INTERVAL '6 months'
ORDER BY record_type, sport_type, value DESC;

-- Best Performances by Distance Category
SELECT 
    sport_type,
    CASE 
        WHEN distance < 7500 THEN 'Short run (≤5-10km)'
        WHEN distance < 17500 THEN 'Medium run (~15km)'
        WHEN distance < 30000 THEN 'Short trail (~20km)'
        WHEN distance < 50000 THEN 'Mid trail (21-42km)'
        WHEN distance < 85000 THEN 'Long trail (43-80km)'
        WHEN distance < 125000 THEN 'Ultra long (80-120km)'
        ELSE 'Ultra XL (120km+)'
    END as distance_category,
    name,
    ROUND(distance/1000, 2) as distance_km,
    ROUND(moving_time/60, 1) as duration_min,
    CASE WHEN average_speed > 0 
         THEN ROUND(1000 / (average_speed * 60), 2) 
         ELSE NULL 
    END as pace_min_per_km,
    start_date
FROM activities 
WHERE sport_type IN ('Run', 'TrailRun')
AND distance > 1000
AND average_speed > 0
AND distance = (
    SELECT MAX(distance) 
    FROM activities a2 
    WHERE a2.sport_type = activities.sport_type
    AND CASE 
        WHEN a2.distance < 7500 THEN 'Short run (≤5-10km)'
        WHEN a2.distance < 17500 THEN 'Medium run (~15km)'
        WHEN a2.distance < 30000 THEN 'Short trail (~20km)'
        WHEN a2.distance < 50000 THEN 'Mid trail (21-42km)'
        WHEN a2.distance < 85000 THEN 'Long trail (43-80km)'
        WHEN a2.distance < 125000 THEN 'Ultra long (80-120km)'
        ELSE 'Ultra XL (120km+)'
    END = CASE 
        WHEN activities.distance < 7500 THEN 'Short run (≤5-10km)'
        WHEN activities.distance < 17500 THEN 'Medium run (~15km)'
        WHEN activities.distance < 30000 THEN 'Short trail (~20km)'
        WHEN activities.distance < 50000 THEN 'Mid trail (21-42km)'
        WHEN activities.distance < 85000 THEN 'Long trail (43-80km)'
        WHEN activities.distance < 125000 THEN 'Ultra long (80-120km)'
        ELSE 'Ultra XL (120km+)'
    END
)
ORDER BY sport_type, distance DESC;

-- ============================================================
-- RECENT ACTIVITY LOG
-- ============================================================

-- Last 30 Days Activity Summary
SELECT * FROM v_recent_activities 
ORDER BY start_date DESC 
LIMIT 30;

-- Training Balance (Last 6 Months)
SELECT * FROM v_training_balance 
ORDER BY sessions DESC;

-- ============================================================
-- PERFORMANCE COMPARISONS
-- ============================================================

-- Recent vs Historical Performance
SELECT 
    sport_type,
    six_month_avg_distance as historical_avg_distance,
    recent_avg_distance,
    distance_change_pct,
    six_month_avg_duration as historical_avg_duration,
    recent_avg_duration,
    duration_change_pct,
    six_month_avg_hr as historical_avg_hr,
    recent_avg_hr,
    hr_change_pct
FROM dashboard_comparisons
WHERE sport_type IN ('Run', 'TrailRun', 'Crossfit')
ORDER BY sport_type;

-- ============================================================
-- TRAINING GOALS & INSIGHTS
-- ============================================================

-- Training Consistency Score (Activities per week)
SELECT 
    sport_type,
    COUNT(*) as total_sessions,
    ROUND(COUNT(*) * 52.0 / 
        (date_diff('day', MIN(start_date), current_date) / 365.25), 1) as sessions_per_year,
    ROUND(COUNT(*) / 
        (date_diff('day', MIN(start_date), current_date) / 7), 1) as sessions_per_week,
    MIN(start_date) as first_activity,
    MAX(start_date) as last_activity
FROM activities 
WHERE start_date >= current_date - INTERVAL '12 months'
GROUP BY sport_type
ORDER BY sessions_per_week DESC;

-- Monthly Volume Trends
SELECT 
    period,
    sport_type,
    total_km,
    total_hours,
    avg_suffer_score,
    LAG(total_km) OVER (PARTITION BY sport_type ORDER BY period) as prev_month_km,
    ROUND((total_km - LAG(total_km) OVER (PARTITION BY sport_type ORDER BY period)) * 100.0 / 
          NULLIF(LAG(total_km) OVER (PARTITION BY sport_type ORDER BY period), 0), 1) as km_change_pct
FROM dashboard_trends 
WHERE period_type = 'monthly'
AND sport_type IN ('Run', 'TrailRun', 'Crossfit')
ORDER BY period DESC, sport_type
LIMIT 24;

-- ============================================================
-- END OF DASHBOARD
-- ============================================================
-- Copy individual queries to the DuckDB UI SQL editor for interactive analysis
-- Modify date ranges and filters as needed for personalized insights
-- ============================================================