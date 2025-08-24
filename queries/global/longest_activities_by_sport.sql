-- Longest activities by sport type
SELECT 
    sport_type,
    name,
    ROUND(distance/1000, 2) as distance_km,
    ROUND(moving_time/3600, 2) as duration_hours,
    start_date
FROM activities
WHERE distance IS NOT NULL
ORDER BY sport_type, distance DESC;