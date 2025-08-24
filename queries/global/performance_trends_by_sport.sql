-- Performance trends by sport type
SELECT 
    sport_type,
    COUNT(*) as activities,
    ROUND(AVG(distance)/1000, 2) as avg_distance_km,
    ROUND(AVG(average_speed * 3.6), 2) as avg_speed_kmh,
    ROUND(AVG(average_heartrate), 1) as avg_heartrate
FROM activities
WHERE sport_type IS NOT NULL
GROUP BY sport_type
ORDER BY activities DESC;