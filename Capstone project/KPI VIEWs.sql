USE airline_db;

-- TOP PRIORITY
-- 1. Monthly seasonal trend view
CREATE OR REPLACE VIEW v_monthly_seasonal_trend AS
SELECT
  MONTH,
  COUNT(*) AS total_flights,
  ROUND(AVG(DEPARTURE_DELAY), 2) AS avg_departure_delay,
  ROUND(AVG(ARRIVAL_DELAY), 2) AS avg_arrival_delay,
  ROUND(SUM(CANCELLED) / COUNT(*), 4) AS cancellation_rate_pct  
FROM flights
GROUP BY MONTH
ORDER BY MONTH;

-- 2. On-Time Departure Rate
CREATE OR REPLACE VIEW v_on_time_departure_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time_departures,
  ROUND(SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS pct_on_time_departure
FROM flights
GROUP BY AIRLINE;

-- 3. On-Time Arrival Rate
CREATE OR REPLACE VIEW v_on_time_arrival_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CASE WHEN ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time_arrivals,
  ROUND(SUM(CASE WHEN ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS pct_on_time_arrival
FROM flights
GROUP BY AIRLINE;

-- 4. Average Departure Delay
CREATE OR REPLACE VIEW v_avg_departure_delay AS
SELECT 
  AIRLINE,
  AVG(DEPARTURE_DELAY) AS avg_departure_delay
FROM flights
GROUP BY AIRLINE;

-- 5. Average Arrival Delay
CREATE OR REPLACE VIEW v_avg_arrival_delay AS
SELECT 
  AIRLINE,
  AVG(ARRIVAL_DELAY) AS avg_arrival_delay
FROM flights
GROUP BY AIRLINE;

-----------------------------------------------------------
-- 6. Delay Causes Analysis 
CREATE OR REPLACE VIEW v_delay_causes AS
SELECT
  AIRLINE,
  SUM(AIR_SYSTEM_DELAY) AS total_air_system_delay,
  SUM(SECURITY_DELAY) AS total_security_delay,
  SUM(AIRLINE_DELAY) AS total_airline_delay,
  SUM(LATE_AIRCRAFT_DELAY) AS total_late_aircraft_delay,
  SUM(WEATHER_DELAY) AS total_weather_delay,
  SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY) AS total_delay,
  ROUND(SUM(AIR_SYSTEM_DELAY) / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 4) AS pct_air_system_delay,
  ROUND(SUM(SECURITY_DELAY) / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 4) AS pct_security_delay,
  ROUND(SUM(AIRLINE_DELAY) / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 4) AS pct_airline_delay,
  ROUND(SUM(LATE_AIRCRAFT_DELAY) / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 4) AS pct_late_aircraft_delay,
  ROUND(SUM(WEATHER_DELAY) / SUM(AIR_SYSTEM_DELAY + SECURITY_DELAY + AIRLINE_DELAY + LATE_AIRCRAFT_DELAY + WEATHER_DELAY), 4) AS pct_weather_delay
FROM flights
GROUP BY AIRLINE;

-- 7. Departure Delay Distribution (delay brackets counts)
CREATE OR REPLACE VIEW v_departure_delay_distribution AS
SELECT 
  AIRLINE,
  SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time,
  SUM(CASE WHEN DEPARTURE_DELAY BETWEEN 1 AND 15 THEN 1 ELSE 0 END) AS minor_delay,
  SUM(CASE WHEN DEPARTURE_DELAY BETWEEN 16 AND 60 THEN 1 ELSE 0 END) AS moderate_delay,
  SUM(CASE WHEN DEPARTURE_DELAY > 60 THEN 1 ELSE 0 END) AS major_delay
FROM flights
GROUP BY AIRLINE;

-- 8. Total Number of flightss
CREATE OR REPLACE VIEW v_total_flightss AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss
FROM flights
GROUP BY AIRLINE;

-- 9. Average Taxi-Out Time
CREATE OR REPLACE VIEW v_avg_taxi_out_time AS
SELECT 
  AIRLINE,
  ROUND(AVG(TAXI_OUT),2) AS avg_taxi_out
FROM flights
GROUP BY AIRLINE;

-- 10. Average Taxi-In Time
CREATE OR REPLACE VIEW v_avg_taxi_in_time AS
SELECT 
  AIRLINE,
  ROUND(AVG(TAXI_IN),2) AS avg_taxi_in
FROM flights
GROUP BY AIRLINE;

-- 11. Dwell Time at Airports (difference between arrival and next departure per tail number)
-- This requires window functions unavailable in My versions before 8.0, so here’s a simplified version per flights pairing by tail number:
CREATE OR REPLACE VIEW v_avg_dwell_time_per_tail AS
SELECT
    TAIL_NUMBER,
    ROUND(AVG(TIMESTAMPDIFF(
        MINUTE,
        ARRIVAL_TIME,
        next_departure
    )), 2) AS avg_dwell_minutes
FROM (
    SELECT
        TAIL_NUMBER,
        ARRIVAL_TIME,
        LEAD(DEPARTURE_TIME) OVER (
            PARTITION BY TAIL_NUMBER
            ORDER BY ARRIVAL_TIME
        ) AS next_departure
    FROM flights
) t
WHERE next_departure IS NOT NULL
GROUP BY TAIL_NUMBER;

-- 12. Average Air Time
CREATE OR REPLACE VIEW v_avg_air_time AS
SELECT 
  AIRLINE,
  ROUND(AVG(AIR_TIME),2) AS avg_air_time
FROM flights
GROUP BY AIRLINE;

-- 13. Average Scheduled vs. Actual Elapsed Time Difference
CREATE OR REPLACE VIEW v_avg_scheduled_vs_actual_elapsed_time AS
SELECT 
  AIRLINE,
  ROUND(AVG(ELAPSED_TIME - SCHEDULED_TIME),2) AS avg_elapsed_time_diff
FROM flights
WHERE ELAPSED_TIME IS NOT NULL AND SCHEDULED_TIME IS NOT NULL
GROUP BY AIRLINE;

-- 14. Cancellation Rate
CREATE OR REPLACE VIEW v_cancellation_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CANCELLED) AS cancellations,
  ROUND(SUM(CANCELLED) / COUNT(*), 4) AS cancellation_rate_pct
FROM flights
GROUP BY AIRLINE;

-- 15. Diversion Rate
CREATE OR REPLACE VIEW v_diversion_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(DIVERTED) AS diversions,
  ROUND(SUM(DIVERTED) / COUNT(*), 4) AS diversion_rate_pct
FROM flights
GROUP BY AIRLINE;

-- 16. Top Reasons for Cancellation (count by reason)
CREATE OR REPLACE VIEW v_top_cancellation_reasons AS
SELECT 
  CANCELLATION_REASON,
  COUNT(*) AS cancellations_count
FROM flights
WHERE CANCELLED = 1
GROUP BY CANCELLATION_REASON
ORDER BY cancellations_count DESC;

-- 17. Average Distance per flights
CREATE OR REPLACE VIEW v_avg_distance_per_flights AS
SELECT 
  AIRLINE,
  AVG(DISTANCE) AS avg_distance
FROM flights
GROUP BY AIRLINE;

-- 18. Top Origins/Destinations by flightss Count
CREATE OR REPLACE VIEW v_top_origins AS
SELECT 
  ORIGIN_AIRPORT,
  COUNT(*) AS flightss_from_origin
FROM flights
GROUP BY ORIGIN_AIRPORT
ORDER BY flightss_from_origin DESC
LIMIT 20;

-- 19 Top Destinations
CREATE OR REPLACE VIEW v_top_destinations AS
SELECT 
  DESTINATION_AIRPORT,
  COUNT(*) AS flightss_to_destination
FROM flights
GROUP BY DESTINATION_AIRPORT
ORDER BY flightss_to_destination DESC
LIMIT 20;

-- 20. Busiest Routes (top route pairs by flightss)
CREATE OR REPLACE VIEW v_busiest_routes AS
SELECT
  ORIGIN_AIRPORT,
  DESTINATION_AIRPORT,
  COUNT(*) AS num_flightss
FROM flights
GROUP BY ORIGIN_AIRPORT, DESTINATION_AIRPORT
ORDER BY num_flightss DESC
LIMIT 20;

-- 21. Airline On-Time Performance (combined for reference)
CREATE OR REPLACE VIEW v_airline_ontime_performance AS
SELECT 
  AIRLINE,
  ROUND(SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS on_time_departure_pct,
  ROUND(SUM(CASE WHEN ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS on_time_arrival_pct
FROM flights
GROUP BY AIRLINE;

-- 22. Airline Cancellation & Diversion Rates (combined)
CREATE OR REPLACE VIEW v_airline_cancellation_diversion AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CANCELLED) AS cancellations,
  ROUND(SUM(CANCELLED) / COUNT(*), 4) AS cancellation_rate_pct,
  SUM(DIVERTED) AS diversions,
  ROUND(SUM(DIVERTED) / COUNT(*), 4) AS diversion_rate_pct
FROM flights
GROUP BY AIRLINE;

-- 23. Aircraft Utilization (flightss per tail number)
CREATE OR REPLACE VIEW v_aircraft_utilization AS
SELECT 
  TAIL_NUMBER,
  COUNT(*) AS flightss_count
FROM flights
GROUP BY TAIL_NUMBER
ORDER BY flightss_count DESC;

-- 24. Delays by Day of Week/Month/Year
CREATE OR REPLACE VIEW v_delays_time_analysis AS
SELECT
  YEAR,
  MONTH,
  DAY_OF_WEEK,
  AVG(DEPARTURE_DELAY) AS avg_departure_delay,
  AVG(ARRIVAL_DELAY) AS avg_arrival_delay
FROM flights
GROUP BY YEAR, MONTH, DAY_OF_WEEK;

-- 25. Peak flights Periods (flightss by scheduled departure hour)
CREATE OR REPLACE VIEW v_peak_flights_periods AS
SELECT 
  FLOOR(SCHEDULED_DEPARTURE / 100) AS hour_of_day,
  COUNT(*) AS flightss_count
FROM flights
GROUP BY hour_of_day
ORDER BY flightss_count DESC;
-- (If you prefer, you can parse SCHEDULED_DEPARTURE as hour instead; it’s stored as integer 0-2359)

-- 26. Airport On-Time Departure Rate
CREATE OR REPLACE VIEW v_airport_ontime_departure AS
SELECT 
  ORIGIN_AIRPORT,
  COUNT(*) AS total_flightss,
  SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time_departures,
  ROUND(SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS pct_on_time_departures
FROM flights
GROUP BY ORIGIN_AIRPORT;

-- 27. Airport Average Delay & Taxi Times
CREATE OR REPLACE VIEW v_avg_delay_originAirport AS
SELECT 
  ORIGIN_AIRPORT,
  ROUND(AVG(DEPARTURE_DELAY),2) AS avg_departure_delay,
  ROUND(AVG(TAXI_OUT),2) AS avg_taxi_out
FROM flights
GROUP BY ORIGIN_AIRPORT;
 
-- 28.Potential Cost Impact 
 -- This view estimates the approximate cost impact of flight delays.
-- Each minute of arrival delay is assumed to cost $1 .
CREATE OR REPLACE VIEW v_delay_cost_estimate AS
SELECT 
  AIRLINE,
  ROUND(SUM(GREATEST(ARRIVAL_DELAY, 0)) * 1, 2) AS estimated_cost_usd
FROM flights
GROUP BY AIRLINE;

-- 29.Day of Week Performance 
-- Purpose: Analyze flight performance by day of the week to identify patterns in delays and on-time rates.
-- Note: In U.S. datasets, the week starts on Sunday (1 = Sunday, 2 = Monday, ..., 7 = Saturday).
-- This helps detect which days have higher average delays or better punctuality.
CREATE OR REPLACE VIEW v_day_of_week_performance AS
SELECT 
  DAY_OF_WEEK,
  COUNT(*) AS total_flights,
  ROUND(AVG(ARRIVAL_DELAY), 2) AS avg_arrival_delay,
  ROUND(SUM(CASE WHEN ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 4) AS on_time_rate
FROM flights
GROUP BY DAY_OF_WEEK
ORDER BY DAY_OF_WEEK;

-- 30.-
-- Purpose: Categorize flights into time-of-day periods (Morning, Afternoon, Evening, Night)
-- based on the scheduled departure time, then calculate average departure delay,
-- average arrival delay, and total flights in each time period.
-- Insight: Helps identify which parts of the day experience the highest congestion
-- or delays, useful for scheduling optimization and operational planning.
CREATE OR REPLACE VIEW v_delays_by_time_period AS
SELECT 
  CASE 
    WHEN FLOOR(SCHEDULED_DEPARTURE / 100) BETWEEN 6 AND 11 THEN 'Morning'
    WHEN FLOOR(SCHEDULED_DEPARTURE / 100) BETWEEN 12 AND 17 THEN 'Afternoon'
    WHEN FLOOR(SCHEDULED_DEPARTURE / 100) BETWEEN 18 AND 23 THEN 'Evening'
    ELSE 'Night'
  END AS time_period,
  AVG(DEPARTURE_DELAY) AS avg_departure_delay,
  AVG(ARRIVAL_DELAY) AS avg_arrival_delay,
  COUNT(*) AS total_flights
FROM flights
GROUP BY time_period;

-- 31. Avg.Delay & Taxi in for Destination airport 
CREATE OR REPLACE VIEW v_avg_delay_destinationAirport AS
SELECT 
  DESTINATION_AIRPORT,
  ROUND(AVG(DEPARTURE_DELAY),2) AS avg_departure_delay,
  ROUND(AVG(TAXI_IN),2) AS avg_taxi_in
FROM flights
GROUP BY DESTINATION_AIRPORT;

-- 32.AVG.departure for every airline
CREATE OR REPLACE VIEW v_avg_delay_airline AS 
SELECT AIRLINE ,ROUND(AVG(DEPARTURE_DELAY),2) avg_delay, ROUND(AVG(TAXI_OUT),2) avg_taxi_out , ROUND(AVG(TAXI_IN),2) avg_taxi_in
FROM flights 
GROUP BY AIRLINE;
