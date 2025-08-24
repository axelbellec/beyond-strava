-- Heart rate analysis (for activities with HR data)
SELECT 
    sport_type,
    COUNT(*) as activities_with_hr,
    ROUND(AVG(average_heartrate), 1) as avg_hr,
    ROUND(AVG(max_heartrate), 1) as avg_max_hr,
    MIN(average_heartrate) as min_avg_hr,
    MAX(max_heartrate) as max_hr_recorded
FROM activities
WHERE has_heartrate = true
GROUP BY sport_type
ORDER BY activities_with_hr DESC;