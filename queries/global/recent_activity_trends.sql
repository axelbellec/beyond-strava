-- Recent activity trends (last 6 months)
SELECT 
    strftime('%Y-%m', start_date) as month,
    sport_type,
    COUNT(*) as activities,
    ROUND(SUM(distance)/1000, 2) as total_km,
    ROUND(AVG(average_heartrate), 1) as avg_hr
FROM activities
WHERE start_date >= current_date - INTERVAL '6 months'
AND start_date IS NOT NULL
GROUP BY month, sport_type
ORDER BY month DESC, activities DESC;