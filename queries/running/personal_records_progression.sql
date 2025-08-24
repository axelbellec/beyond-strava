-- Personal records and progression tracking
-- Tracks your best performances across different distances and time periods
WITH distance_prs AS (
    SELECT 
        sport_type,
        name,
        distance,
        ROUND(distance/1000, 2) as distance_km,
        moving_time,
        ROUND(moving_time/60.0, 2) as duration_min,
        CASE WHEN average_speed > 0 
             THEN ROUND(1000 / (average_speed * 60), 2) 
             ELSE NULL 
        END as pace_min_per_km,
        average_heartrate,
        max_heartrate,
        total_elevation_gain,
        start_date,
        ROW_NUMBER() OVER (
            PARTITION BY sport_type, 
            CASE 
                WHEN distance < 2000 THEN '1km-2km'
                WHEN distance < 3000 THEN '2km-3km'
                WHEN distance < 4000 THEN '3km-4km'
                WHEN distance < 6000 THEN '4km-6km'
                WHEN distance < 8000 THEN '6km-8km'
                WHEN distance < 12000 THEN '8km-12km'
                WHEN distance < 16000 THEN '12km-16km'
                WHEN distance < 22000 THEN '16km-22km'
                ELSE '22km+'
            END
            ORDER BY average_speed DESC
        ) as speed_rank,
        ROW_NUMBER() OVER (
            PARTITION BY sport_type
            ORDER BY distance DESC
        ) as distance_rank,
        CASE 
            WHEN distance < 2000 THEN '1km-2km'
            WHEN distance < 3000 THEN '2km-3km'
            WHEN distance < 4000 THEN '3km-4km'
            WHEN distance < 6000 THEN '4km-6km'
            WHEN distance < 8000 THEN '6km-8km'
            WHEN distance < 12000 THEN '8km-12km'
            WHEN distance < 16000 THEN '12km-16km'
            WHEN distance < 22000 THEN '16km-22km'
            ELSE '22km+'
        END as distance_category
    FROM activities
    WHERE sport_type IN ('Run', 'TrailRun')
    AND distance > 1000
    AND average_speed > 0
    AND start_date IS NOT NULL
)
SELECT 
    'FASTEST BY DISTANCE' as record_type,
    sport_type,
    distance_category,
    name,
    distance_km,
    duration_min,
    pace_min_per_km,
    average_heartrate as avg_hr,
    total_elevation_gain as elevation_m,
    start_date
FROM distance_prs
WHERE speed_rank = 1
AND pace_min_per_km BETWEEN 3 AND 12

UNION ALL

SELECT 
    'LONGEST RUNS' as record_type,
    sport_type,
    'Distance PR' as distance_category,
    name,
    distance_km,
    duration_min,
    pace_min_per_km,
    average_heartrate,
    total_elevation_gain,
    start_date
FROM distance_prs
WHERE distance_rank <= 10

ORDER BY record_type, sport_type, distance_km DESC;