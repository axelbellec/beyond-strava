-- Monthly activity summary
SELECT 
    strftime('%Y-%m', start_date) as month,
    COUNT(*) as activities,
    ROUND(SUM(distance)/1000, 2) as total_km,
    ROUND(AVG(distance)/1000, 2) as avg_km_per_activity,
    ROUND(SUM(moving_time)/3600, 2) as total_hours
FROM activities
WHERE start_date IS NOT NULL
GROUP BY month
ORDER BY month DESC;