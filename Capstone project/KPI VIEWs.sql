USE airline_flight_delays;


-- 1. On-Time Departure Rate

CREATE OR REPLACE VIEW v_on_time_departure_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time_departures,
  ROUND(100 * SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_on_time_departure
FROM flights
GROUP BY AIRLINE;
-- 2. On-Time Arrival Rate

CREATE OR REPLACE VIEW v_on_time_arrival_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CASE WHEN ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time_arrivals,
  ROUND(100 * SUM(CASE WHEN ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_on_time_arrival
FROM flights
GROUP BY AIRLINE;
-- 3. Average Departure Delay

CREATE OR REPLACE VIEW v_avg_departure_delay AS
SELECT 
  AIRLINE,
  AVG(DEPARTURE_DELAY) AS avg_departure_delay
FROM flights
GROUP BY AIRLINE;
-- 4. Average Arrival Delay

CREATE OR REPLACE VIEW v_avg_arrival_delay AS
SELECT 
  AIRLINE,
  AVG(ARRIVAL_DELAY) AS avg_arrival_delay
FROM flights
GROUP BY AIRLINE;
-- 5. Delay Causes Analysis (each cause average)

CREATE OR REPLACE VIEW v_delay_causes AS
SELECT 
  AIRLINE,
  AVG(AIR_SYSTEM_DELAY) AS avg_air_system_delay,
  AVG(SECURITY_DELAY) AS avg_security_delay,
  AVG(AIRLINE_DELAY) AS avg_airline_delay,
  AVG(LATE_AIRCRAFT_DELAY) AS avg_late_aircraft_delay,
  AVG(WEATHER_DELAY) AS avg_weather_delay
FROM flights
GROUP BY AIRLINE;
-- 6. Departure Delay Distribution (delay brackets counts)

CREATE OR REPLACE VIEW v_departure_delay_distribution AS
SELECT 
  AIRLINE,
  SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time,
  SUM(CASE WHEN DEPARTURE_DELAY BETWEEN 1 AND 15 THEN 1 ELSE 0 END) AS minor_delay,
  SUM(CASE WHEN DEPARTURE_DELAY BETWEEN 16 AND 60 THEN 1 ELSE 0 END) AS moderate_delay,
  SUM(CASE WHEN DEPARTURE_DELAY > 60 THEN 1 ELSE 0 END) AS major_delay
FROM flights
GROUP BY AIRLINE;
-- 7. Total Number of flightss

CREATE OR REPLACE VIEW v_total_flightss AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss
FROM flights
GROUP BY AIRLINE;
-- 8. Average Taxi-Out Time

CREATE OR REPLACE VIEW v_avg_taxi_out_time AS
SELECT 
  AIRLINE,
  AVG(TAXI_OUT) AS avg_taxi_out
FROM flights
GROUP BY AIRLINE;
-- 9. Average Taxi-In Time

CREATE OR REPLACE VIEW v_avg_taxi_in_time AS
SELECT 
  AIRLINE,
  AVG(TAXI_IN) AS avg_taxi_in
FROM flights
GROUP BY AIRLINE;
-- 10. Dwell Time at Airports (difference between arrival and next departure per tail number)
-- This requires window functions unavailable in My versions before 8.0, so here’s a simplified version per flights pairing by tail number:


CREATE OR REPLACE VIEW v_avg_dwell_time_per_tail AS
SELECT 
  TAIL_NUMBER,
  AVG(SCHEDULED_DEPARTURE - SCHEDULED_ARRIVAL) AS avg_dwell_time
FROM flights
WHERE TAIL_NUMBER IS NOT NULL
GROUP BY TAIL_NUMBER;
-- 11. Average Air Time

CREATE OR REPLACE VIEW v_avg_air_time AS
SELECT 
  AIRLINE,
  AVG(AIR_TIME) AS avg_air_time
FROM flights
GROUP BY AIRLINE;
-- 12. Average Scheduled vs. Actual Elapsed Time Difference

CREATE OR REPLACE VIEW v_avg_scheduled_vs_actual_elapsed_time AS
SELECT 
  AIRLINE,
  AVG(ELAPSED_TIME - SCHEDULED_TIME) AS avg_elapsed_time_diff
FROM flights
GROUP BY AIRLINE;
-- 13. Cancellation Rate

CREATE OR REPLACE VIEW v_cancellation_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CANCELLED) AS cancellations,
  ROUND(100 * SUM(CANCELLED) / COUNT(*), 2) AS cancellation_rate_pct
FROM flights
GROUP BY AIRLINE;
-- 14. Diversion Rate

CREATE OR REPLACE VIEW v_diversion_rate AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(DIVERTED) AS diversions,
  ROUND(100 * SUM(DIVERTED) / COUNT(*), 2) AS diversion_rate_pct
FROM flights
GROUP BY AIRLINE;
-- 15. Top Reasons for Cancellation (count by reason)

CREATE OR REPLACE VIEW v_top_cancellation_reasons AS
SELECT 
  CANCELLATION_REASON,
  COUNT(*) AS cancellations_count
FROM flights
WHERE CANCELLED = 1
GROUP BY CANCELLATION_REASON
ORDER BY cancellations_count DESC;
-- 16. Route Frequency

CREATE OR REPLACE VIEW v_route_frequency AS
SELECT 
  ORIGIN_AIRPORT,
  DESTINATION_AIRPORT,
  COUNT(*) AS num_flightss
FROM flights
GROUP BY ORIGIN_AIRPORT, DESTINATION_AIRPORT;
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

CREATE OR REPLACE VIEW v_top_destinations AS
SELECT 
  DESTINATION_AIRPORT,
  COUNT(*) AS flightss_to_destination
FROM flights
GROUP BY DESTINATION_AIRPORT
ORDER BY flightss_to_destination DESC
LIMIT 20;
-- 19. Busiest Routes (top route pairs by flightss)

CREATE OR REPLACE VIEW v_busiest_routes AS
SELECT
  ORIGIN_AIRPORT,
  DESTINATION_AIRPORT,
  COUNT(*) AS num_flightss
FROM flights
GROUP BY ORIGIN_AIRPORT, DESTINATION_AIRPORT
ORDER BY num_flightss DESC
LIMIT 20;
-- 20. Airline On-Time Performance (combined for reference)

CREATE OR REPLACE VIEW v_airline_ontime_performance AS
SELECT 
  AIRLINE,
  ROUND(100 * SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_departure_pct,
  ROUND(100 * SUM(CASE WHEN ARRIVAL_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS on_time_arrival_pct
FROM flights
GROUP BY AIRLINE;
-- 21. Airline Cancellation & Diversion Rates (combined)

CREATE OR REPLACE VIEW v_airline_cancellation_diversion AS
SELECT 
  AIRLINE,
  COUNT(*) AS total_flightss,
  SUM(CANCELLED) AS cancellations,
  ROUND(100 * SUM(CANCELLED) / COUNT(*), 2) AS cancellation_rate_pct,
  SUM(DIVERTED) AS diversions,
  ROUND(100 * SUM(DIVERTED) / COUNT(*), 2) AS diversion_rate_pct
FROM flights
GROUP BY AIRLINE;
-- 22. Aircraft Utilization (flightss per tail number)

CREATE OR REPLACE VIEW v_aircraft_utilization AS
SELECT 
  TAIL_NUMBER,
  COUNT(*) AS flightss_count
FROM flights
GROUP BY TAIL_NUMBER
ORDER BY flightss_count DESC;
-- 23. Delays by Day of Week/Month/Year

CREATE OR REPLACE VIEW v_delays_time_analysis AS
SELECT
  YEAR,
  MONTH,
  DAY_OF_WEEK,
  AVG(DEPARTURE_DELAY) AS avg_departure_delay,
  AVG(ARRIVAL_DELAY) AS avg_arrival_delay
FROM flights
GROUP BY YEAR, MONTH, DAY_OF_WEEK;
-- 24. Peak flights Periods (flightss by scheduled departure hour)

CREATE OR REPLACE VIEW v_peak_flights_periods AS
SELECT 
  HOUR(TIMESTAMP(CONCAT_WS(' ', LPAD(MONTH,2,'0'), LPAD(DAY,2,'0'), YEAR))) AS hour_of_day,
  COUNT(*) AS flightss_count
FROM flights
GROUP BY hour_of_day
ORDER BY flightss_count DESC;
-- (If you prefer, you can parse SCHEDULED_DEPARTURE as hour instead; it’s stored as integer 0-2359)

-- 25. Airport On-Time Departure Rate

CREATE OR REPLACE VIEW v_airport_ontime_departure AS
SELECT 
  ORIGIN_AIRPORT,
  COUNT(*) AS total_flightss,
  SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) AS on_time_departures,
  ROUND(100 * SUM(CASE WHEN DEPARTURE_DELAY <= 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_on_time_departures
FROM flights
GROUP BY ORIGIN_AIRPORT;
-- 26. Airport Average Delay & Taxi Times

CREATE OR REPLACE VIEW v_airport_delay_taxi AS
SELECT 
  ORIGIN_AIRPORT,
  AVG(DEPARTURE_DELAY) AS avg_departure_delay,
  AVG(TAXI_OUT) AS avg_taxi_out,
  AVG(TAXI_IN) AS avg_taxi_in
FROM flights
GROUP BY ORIGIN_AIRPORT;
-- 27. Top Weather/Delay-Prone Airports (by weather delay)

CREATE OR REPLACE VIEW v_weather_delay_prone_airports AS
SELECT 
  ORIGIN_AIRPORT,
  SUM(WEATHER_DELAY) AS total_weather_delay,
  COUNT(*) AS total_flightss,
  ROUND(SUM(WEATHER_DELAY) / COUNT(*), 2) AS avg_weather_delay_per_flights
FROM flights
GROUP BY ORIGIN_AIRPORT
ORDER BY total_weather_delay DESC
LIMIT 20;