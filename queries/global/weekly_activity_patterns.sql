-- Weekly activity patterns
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
    COUNT(*) as activities,
    ROUND(AVG(distance)/1000, 2) as avg_distance_km
FROM activities
WHERE start_date IS NOT NULL
GROUP BY day_of_week, day_name
ORDER BY day_of_week;