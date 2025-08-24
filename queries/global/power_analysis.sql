-- Power analysis (for activities with power data)
SELECT 
    sport_type,
    COUNT(*) as activities_with_power,
    ROUND(AVG(average_watts), 1) as avg_watts,
    ROUND(AVG(max_watts), 1) as avg_max_watts,
    ROUND(AVG(kilojoules), 1) as avg_kilojoules
FROM activities
WHERE device_watts = true AND average_watts IS NOT NULL
GROUP BY sport_type
ORDER BY activities_with_power DESC;